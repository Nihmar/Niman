// The Hindi strings.
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class HindiStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
    'जनवरी',
    'फ़रवरी',
    'मार्च',
    'अप्रैल',
    'मई',
    'जून',
    'जुलाई',
    'अगस्त',
    'सितंबर',
    'अक्टूबर',
    'नवंबर',
    'दिसंबर',
  ];
  @override
  List<String> get monthNamesShort => const [
    'जन',
    'फ़र',
    'मार्च',
    'अप्रै',
    'मई',
    'जून',
    'जुल',
    'अग',
    'सित',
    'अक्टू',
    'नव',
    'दिस',
  ];
  @override
  List<String> get weekdayNames => const [
    'सोमवार',
    'मंगलवार',
    'बुधवार',
    'गुरुवार',
    'शुक्रवार',
    'शनिवार',
    'रविवार',
  ];
  @override
  List<String> get weekdayNamesShort => const [
    'सोम',
    'मंगल',
    'बुध',
    'गुरु',
    'शुक्र',
    'शनि',
    'रवि',
  ];

  // Settings: editor toggles.
  @override
  String get trashTitle => 'ट्रैश';
  @override
  String get trashSubtitle =>
      'हटाए गए चीज़ें .trash/ में जाती हैं (बंद = हमेशा के लिए हटाएँ)';
  @override
  String get trashAutoEmptyTitle => 'ट्रैश अपने आप खाली करें';
  @override
  String get trashAutoEmptySubtitle =>
      'लाइब्रेरी खुलने पर पुरानी हटाई गई चीज़ें हमेशा के लिए मिट जाती हैं';
  @override
  String trashAutoEmptyValue(int days) => days == 0 ? 'कभी नहीं' : '$days दिन';
  @override
  String get debugLogsTitle => 'डिबग लॉग';
  @override
  String get debugLogsSubtitle => 'ऐप के घटनाक्रम को मेमोरी बफ़र में दर्ज रखें';
  @override
  String get lineNumbersTitle => 'पंक्ति संख्याएँ';
  @override
  String get lineNumbersSubtitle => 'नोट एडिटर में पंक्ति-संख्या स्तंभ दिखाएँ';
  @override
  String get readableLineLengthTitle => 'पढ़ने योग्य पंक्ति लंबाई';
  @override
  String get readableLineLengthSubtitle =>
      'नोट का टेक्स्ट विंडो की पूरी चौड़ाई के बजाय बीच के एक कॉलम में रखें';
  @override
  String get noteColumnWidthTitle => 'कॉलम की चौड़ाई';
  @override
  String get noteColumnWidthSubtitle =>
      'नोट का कॉलम कितना चौड़ा है, पिक्सेल में';
  @override
  String noteColumnWidthValue(int pixels) => '$pixels px';
  @override
  String get keyboardOnOpenTitle => 'खोलने पर कीबोर्ड';
  @override
  String get keyboardOnOpenSubtitle =>
      'नोट खोलते ही कीबोर्ड दिखाएँ (बंद = पहली टैप पर)';
  @override
  String get editorKindSource => 'Markdown स्रोत';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get editorKindSourceSubtitle => 'Markdown स्रोत, जैसा लिखा है';
  @override
  String get editorKindWysiwygSubtitle => 'फ़ॉर्मेटेड टेक्स्ट, सीधे संपादित';
  @override
  String get settingsFolderToCreate => 'बनाना है';
  @override
  String get settingsSearchHint => 'सेटिंग खोजें';
  @override
  String settingsSearchResults(int count) =>
      count == 1 ? '1 सेटिंग मिली' : '$count सेटिंग मिलीं';
  @override
  String get settingsToggleOn => 'चालू';
  @override
  String get settingsToggleOff => 'बंद';
  @override
  String get settingsPreviewEnabledTitle => 'पूर्वावलोकन';
  @override
  String get settingsPreviewEnabledSubtitle =>
      'स्रोत एडिटर के बगल में रेंडर किया गया नोट दिखाएँ';
  @override
  String get switchToWysiwygTooltip => 'WYSIWYG एडिटर पर जाएँ';
  @override
  String get switchToSourceTooltip => 'Markdown स्रोत पर जाएँ';
  @override
  String get switchToSourceLabel => 'स्रोत';
  @override
  String get switchToWysiwygLabel => 'WYSIWYG';
  @override
  String get wysiwygTooLarge =>
      'यह नोट WYSIWYG एडिटर के लिए बहुत बड़ा है। इसे Markdown स्रोत में खोलें।';

  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'दिखावट';
  @override
  String get settingsSectionEditor => 'एडिटर';
  @override
  String get settingsSectionLibrary => 'लाइब्रेरी';
  @override
  String get settingsSectionReminders => 'रिमाइंडर';
  @override
  String get settingsSectionShortcuts => 'कीबोर्ड';
  @override
  String get keyboardShortcutsTitle => 'कीबोर्ड शॉर्टकट';

  // Settings home (issue #104): the groups the areas sit under.
  @override
  String get settingsGroupApp => 'App';
  @override
  String settingsGroupLibrary(String name) => 'लाइब्रेरी $name';
  @override
  String get settingsGroupLibraryHint => 'केवल इस लाइब्रेरी के लिए';
  @override
  String get settingsGroupMaintenance => 'रखरखाव';

  // Settings home rows.
  @override
  String get settingsAreaFolders => 'फ़ोल्डर और पथ';
  @override
  String get settingsAreaTrashHistory => 'ट्रैश और क्रोनोलॉजी';
  @override
  String get settingsAreaDiagnostics => 'निदान और जानकारी';
  @override
  String get settingsAreaKeyboardDisabled =>
      'कनेक्टेड फिज़िकल कीबोर्ड ज़रूरी है';
  @override
  String get settingsSectionUpdates => 'अपडेट';
  @override
  String get autoUpdateTitle => 'स्वचालित अपडेट';
  @override
  String get autoUpdateSubtitle =>
      'लॉन्च पर और हर 6 घंटे में GitHub Releases जाँचें';
  @override
  String get checkForUpdatesTitle => 'अपडेट जाँचें';
  @override
  String updateAvailableMessage(Object version) => 'Niman $version उपलब्ध है';
  @override
  String get updateUpToDate => 'Niman अप-टू-डेट है';
  @override
  String get updateCheckFailed => 'अपडेट की जाँच विफल';
  @override
  String updateSavedTo(Object path) => 'अपडेट $path में सहेजा गया';
  @override
  String get updateInstallerStarted => 'इंस्टॉलर शुरू हुआ';
  @override
  String get settingsSectionDiagnostics => 'निदान';
  @override
  String get settingsSpellCheckTitle => 'व्याकरण जाँचें';
  @override
  String get settingsSpellCheckSubtitle =>
      'लिखते समय गलत लिखी शब्दों के नीचे रेखा खींचें।';
  @override
  String get spellCheckDictionaryTitle => 'शब्दकोश';
  @override
  String get spellCheckDictionarySystem => 'सिस्टम डिफ़ॉल्ट';
  @override
  String get spellCheckDictionaryChoiceTitle => 'शब्दकोश चुनें';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      'हर वह भाषा चुनें जिसमें यह लाइब्रेरी लिखी गई है। कोई शब्द तभी सही '
      'है जब कोई चुना हुआ शब्दकोश उसे जानता है; कुछ न चुनने पर सिस्टम '
      'भाषा तय करती है।';
  @override
  String get spellCheckNoDictionaries => 'इस सिस्टम पर कोई शब्दकोश नहीं मिला।';

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => 'व्याकरण जाँचें';
  @override
  String get spellCheckTitle => 'व्याकरण';
  @override
  String get spellCheckEmpty => 'कोई व्याकरण की ग़लती नहीं।';
  @override
  String get spellCheckUnavailable => 'hunspell इस सिस्टम पर इंस्टॉल नहीं है।';
  @override
  String get spellCheckNoSuggestions => 'कोई सुझाव नहीं';
  @override
  String spellCheckCount(int count) => '$count की समीक्षा बाकी';
  @override
  String spellCheckLine(int line) => 'पंक्ति $line';
  @override
  String get addWordToDictionary => 'शब्दकोश में जोड़ें';

  @override
  String indentWidthValue(int spaces) => '$spaces स्पेस';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => 'चमक';
  @override
  String get themeBrightnessSubtitle => 'लाइट, डार्क, या डिवाइस की सेटिंग जैसा';
  @override
  String get themeBrightnessSystem => 'सिस्टम';
  @override
  String get themeBrightnessDay => 'लाइट';
  @override
  String get themeBrightnessNight => 'डार्क';
  @override
  String get themePaletteTitle => 'पैलेट';
  @override
  String get themePaletteSubtitle => 'इंटरफ़ेस और नोट के रंग';
  @override
  String get themePaletteSystem => 'सिस्टम';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'इंटरफ़ेस टेक्स्ट का आकार';
  @override
  String get uiTextScaleSubtitle =>
      'ट्री, टैब्स और डायलॉग्स; सिस्टम सेटिंग के ऊपर';
  @override
  String get noteTextScaleTitle => 'नोट्स के टेक्स्ट का आकार';
  @override
  String get noteTextScaleSubtitle =>
      'एडिटर और पूर्वावलोकन, जो हमेशा एक-दूसरे से मिलते हैं';

  // Settings: preview mode.
  @override
  String get previewModeTitle => 'पूर्वावलोकन मोड';
  @override
  String get previewModeSubtitle =>
      'पूर्वावलोकन स्क्रीन एडिटर के साथ बाँटता है या उसकी जगह लेता है';
  @override
  String get previewModeAuto => 'साथ-साथ';
  @override
  String get previewModeSwitch => 'फुल स्क्रीन';
  @override
  String get splitRatioTitle => 'विभाजन की चौड़ाई';
  @override
  String get splitRatioSubtitle => 'पूर्वावलोकन साथ-साथ है तो एडिटर का हिस्सा';

  // Settings: editor formatting.
  @override
  String get linkTypeTitle => 'लिंक का फ़ॉर्मेट';
  @override
  String get linkTypeSubtitle => 'एडिटर का लिंक बटन क्या डालता है';
  @override
  String get linkTypeWikilink => 'विकिलिंक';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get missingNoteLocationTitle => 'ग़ायब नोट्स बनाएँ';
  @override
  String get missingNoteLocationRoot => 'लाइब्रेरी रूट';
  @override
  String get missingNoteLocationCurrentFolder => 'वर्तमान फ़ोल्डर';
  @override
  String get indentWidthTitle => 'इंडेंट की चौड़ाई';
  @override
  String get indentWidthSubtitle =>
      'एडिटर में हर इंडेंट स्तर पर जोड़ी गई spaces';

  // Settings: language (T-L10N-04).
  @override
  String get languageTitle => 'भाषा';
  @override
  String get languageSubtitle => 'ऐप के अपने टेक्स्ट की भाषा';
  @override
  String get languageSystem => 'सिस्टम';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'एक आइटम जोड़ें';
  @override
  String get listAddTooltip => 'एक आइटम जोड़ें';
  @override
  String get listEmpty => 'अभी कोई आइटम नहीं';
  @override
  String get listDragHandleLabel => 'आइटम का क्रम बदलें';

  // Audio note kind (issue #56).
  @override
  String get audioEmpty => 'अभी कोई रिकॉर्डिंग नहीं';
  @override
  String get audioRecord => 'रिकॉर्ड करें';
  @override
  String get audioStop => 'रोकें';
  @override
  String get audioPlay => 'चलाएँ';
  @override
  String get audioDelete => 'रिकॉर्डिंग हटाएँ';
  @override
  String get audioImport => 'ऑडियो फ़ाइल आयात करें';
  @override
  String get audioRecording => 'रिकॉर्ड हो रहा है…';
  @override
  String get audioPermissionDenied =>
      'माइक्रोफ़ोन की अनुमति नहीं मिली — रिकॉर्डिंग के लिए यह ज़रूरी है।';
  @override
  String get newAudioNoteTitle => 'नया वॉइस नोट';
  @override
  String get newAudioNoteDefault => 'मेरी रिकॉर्डिंग';
  @override
  String get showAudioTooltip => 'रिकॉर्डिंग दिखाएँ';
  @override
  String get audioMessageHint => 'नोट लिखें…';
  @override
  String get audioSend => 'भेजें';
  @override
  String get audioRename => 'रिकॉर्डिंग का नाम बदलें';
  @override
  String get audioDescriptionHint => 'इस रिकॉर्डिंग का वर्णन करें…';
  @override
  String get audioEditDescription => 'वर्णन संपादित करें';
  @override
  String get audioDeleteNote => 'नोट हटाएँ';
  @override
  String get audioEditNote => 'नोट संपादित करें';
  @override
  String get audioPause => 'रोकें';
  @override
  String get audioEditTitle => 'शीर्षक संपादित करें';
  @override
  String get audioTitleHint => 'इस रिकॉर्डिंग का शीर्षक…';
  @override
  String audioUntitled(int n) => 'रिकॉर्डिंग $n';
  @override
  String get audioMoreActions => 'और क्रियाएँ';
  @override
  String get audioDiscardRecording => 'रिकॉर्डिंग रद्द करें';
  @override
  String get audioPauseRecording => 'रिकॉर्डिंग रोकें';
  @override
  String get audioResumeRecording => 'रिकॉर्डिंग फिर शुरू करें';
  @override
  String get audioRecordingPaused => 'रुकी हुई';
  @override
  String get audioSavingRecording => 'सहेजा जा रहा है…';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'क्विक नोट';
  @override
  String get trayOpen => 'Niman खोलें';
  @override
  String get trayQuit => 'बंद करें';
  @override
  String get closeToTrayTitle => 'ट्रे में बंद करें';
  @override
  String get closeToTraySubtitle =>
      'विंडो का × Niman को छिपा देता है और चलता छोड़ देता है, इसलिए रिमाइंडर '
      'आते रहते हैं। ट्रे मेन्यू से बाहर निकलें।';
  @override
  String get shortcutNewTodo => 'नया टू-डू';
  @override
  String get shortcutNewNote => 'नया नोट';
  @override
  String get shortcutNewList => 'नई सूची';
  @override
  String get shortcutNewAudio => 'नया वॉइस नोट';
  @override
  String get shortcutToggleSidebar => 'फ़ाइल ट्री दिखाएँ/छिपाएँ';
  @override
  String get shortcutCloseTab => 'मौजूदा नोट बंद करें';
  @override
  String get shortcutNextTab => 'अगला खुला नोट';
  @override
  String get shortcutPreviousTab => 'पिछला खुला नोट';
  @override
  String get shortcutEditorSection => 'एडिटर में';
  @override
  String get shortcutFormatSection => 'फ़ॉर्मैटिंग';
  @override
  String get shortcutFind => 'ढूँढें';
  @override
  String get shortcutReplace => 'ढूँढें और बदलें';
  @override
  String get shortcutSavingNote =>
      'बदलाव अपने-आप सहेजे जाते हैं: सहेजने का कोई शॉर्टकट नहीं है।';

  // Editor status bar.
  @override
  String get noteStatusLoading => 'लोड हो रहा है…';
  @override
  String get noteStatusSaving => 'सहेजा जा रहा है…';
  @override
  String get noteStatusUnsaved => 'सहेजा नहीं गया';
  @override
  String get noteStatusSaved => 'सहेजा गया';
  @override
  String get noteStatusError => 'त्रुटि';
  @override
  String get noteNotText =>
      'यह फ़ाइल टेक्स्ट नोट नहीं है, इसलिए Niman इसे यहाँ नहीं दिखा सकता।';
  @override
  String get noteLoadFailed => 'यह नोट खोला नहीं जा सका।';
  @override
  String wordCount(int count) => '$count शब्द';
  @override
  String get outlineTooltip => 'आउटलाइन';
  @override
  String get outlineNoHeadings => 'कोई हेडिंग नहीं';
  @override
  String get outlineNoTitle => '(बिना शीर्षक)';

  // Editor toolbar: one name per button.
  @override
  String get toolbarBold => 'बोल्ड';
  @override
  String get toolbarItalic => 'इटैलिक';
  @override
  String get toolbarStrikethrough => 'स्ट्राइक-थ्रू';
  @override
  String get toolbarSuperscript => 'सुपरस्क्रिप्ट';
  @override
  String get toolbarUnderline => 'अंडरलाइन';
  @override
  String get toolbarLink => 'लिंक';
  @override
  String get toolbarCode => 'कोड ब्लॉक';
  @override
  String get toolbarImage => 'छवि डालें';
  @override
  String get toolbarHeading => 'हेडिंग';
  @override
  String get toolbarList => 'सूची';
  @override
  String get toolbarOrderedList => 'क्रमांकित सूची';
  @override
  String get toolbarQuote => 'उद्धरण';
  @override
  String get toolbarIndent => 'इंडेंट बढ़ाएँ';
  @override
  String get toolbarOutdent => 'इंडेंट घटाएँ';

  // Editor tools (#136): the Tools button, the sheet it opens, and
  // the list count that is the first tool in it.
  @override
  String get toolbarTools => 'उपकरण';
  @override
  String get editorToolsTitle => 'संपादक उपकरण';
  @override
  String get toolCountListTitle => 'सूची गिनें';
  @override
  String get toolCountListSubtitle =>
      'पंक्तियाँ जो सूचीबद्ध करती हैं उसका योग, चेकलिस्ट के रूप में';
  @override
  String get toolCountListNeedsList =>
      'इस नोट में गिनने के लिए कोई सूची नहीं है';
  @override
  String get tallySourceLabel => 'सूची';
  @override
  String get tallyCutLabel => 'हर पंक्ति को ऐसे पढ़ें';
  @override
  String get tallyCutDash => 'नाम - मान';
  @override
  String get tallyCutColon => 'नाम: मान';
  @override
  String get tallyCutCommas => 'अल्पविराम से अलग किए मान';
  @override
  String get tallyCutWhole => 'पूरी पंक्ति, एक ही मान के रूप में';
  @override
  String get tallySortLabel => 'क्रम';
  @override
  String get tallySortCount => 'सबसे अधिक पहले';
  @override
  String get tallySortAlphabetical => 'वर्णानुक्रम';
  @override
  String get tallySortFirstSeen => 'सूची के क्रम में';
  @override
  String get tallyInsert => 'डालें';
  @override
  String get tallyUpdate => 'अपडेट करें';
  @override
  String get tallyNothingToCount => 'यहाँ गिनने के लिए कुछ नहीं है';
  @override
  String get headingDialogTitle => 'हेडिंग स्तर';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => 'एडिटर टूलबार';
  @override
  String get toolbarSettingsHint =>
      'क्रम बदलने के लिए खींचें; आँख बटन दिखाती या छिपाती है।';
  @override
  String get toolbarShowButton => 'दिखाएँ';
  @override
  String get toolbarHideButton => 'छिपाएँ';
  @override
  String get toolbarResetOrder => 'डिफ़ॉल्ट वापस करें';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => 'पूर्वावलोकन दिखाएँ';
  @override
  String get showEditorTooltip => 'एडिटर दिखाएँ';
  @override
  String get enterFullScreenTooltip => 'फुल स्क्रीन';
  @override
  String get exitFullScreenTooltip => 'फुल स्क्रीन से बाहर';

  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '(कच्चा HTML तालिका)';

  // Search (T-M3-05).
  @override
  String get searchHint => 'नोट्स में खोजें';
  @override
  String get searchModeWords => 'शब्द';
  @override
  String get searchModeContains => 'सामिल है';
  @override
  String get searchEmptyHint =>
      'लाइब्रेरी में खोजने के लिए टाइप करें, या फ़्रंटमैटर से छानने के '
      'लिए key = value';
  @override
  String get searchTooShortHint => 'कम से कम 2 अक्षर टाइप करें';
  @override
  String get searchNoMatches => 'कोई मेल नहीं';
  @override
  String get searchLoadMore => 'और दिखाएँ';

  // Replace (T-M3-10).
  @override
  String get replaceTooltip => 'बदलें…';
  @override
  String get replaceInNoteAction => 'इस नोट में बदलें…';
  @override
  String get replaceInThisNote => 'इस नोट में बदलें';
  @override
  String get replaceWithLabel => 'इससे बदलें';
  @override
  String get replaceCaseSensitive => 'केस-सांवेदनशील';
  @override
  String get replaceWholeWordsHint =>
      'सिर्फ़ पूरे शब्द के ठीक-ठीक मेल बदले जाएँगे';
  @override
  String get replaceConfirm => 'बदलें';
  @override
  String get replaceCancel => 'बंद करें';
  @override
  String get replaceUnavailable => 'अभी बदलना उपलब्ध नहीं है';

  // Editor find & replace.
  @override
  String get findInNoteTooltip => 'नोट में खोजें';
  @override
  String get editorFindHint => 'खोजें';
  @override
  String get editorReplaceHint => 'बदलें';
  @override
  String get editorFindCaseTooltip => 'केस-सांवेदनशील';
  @override
  String get editorFindPreviousTooltip => 'पिछला मेल';
  @override
  String get editorFindNextTooltip => 'अगला मेल';
  @override
  String get editorFindCloseTooltip => 'खोज बंद करें';
  @override
  String get editorFindReplaceModeTooltip => 'बदलाव मोड';
  @override
  String get editorReplaceOneTooltip => 'यह मेल बदलें';
  @override
  String get editorReplaceAllTooltip => 'सब बदलें';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => 'टैग';
  @override
  String get tagsTitle => 'टैग';
  @override
  String get tagsEmpty => 'अभी कोई टैग नहीं — #tag या फ़्रंटमैटर टैग जोड़ें';
  @override
  String get tagsBackTooltip => 'खोज पर वापस';
  @override
  String get tagsNotesEmpty => 'इस टैग वाला कोई नोट नहीं';
  @override
  String tagsNotesCapped(int limit) =>
      'सिर्फ़ पहले $limit सूचीबद्ध हैं — संकुचित करने के लिए टैग खोजें';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => 'लिंक नहीं मिला';
  @override
  String get headingNotFoundTitle => 'हेडिंग नहीं मिली';
  @override
  String get ambiguousLinkTitle => 'कई नोट्स मेल खाते हैं';
  @override
  String get openLinkFailed => 'लिंक नहीं खोला जा सका';

  // Dead-link note creation (issue #78).
  @override
  String get missingNoteDialogTitle => 'नोट मौजूद नहीं है';
  @override
  String missingNoteDialogBody(String path) => 'क्या "$path" बनाना है?';
  @override
  String missingNoteFolderMissing(String folder) =>
      'फ़ोल्डर "$folder" मौजूद नहीं है';

  // Task lists (T-TD-04).
  @override
  String get todoOpen => 'बाकी';
  @override
  String get todoDone => 'पूरे';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => 'सभी तारीख़ें';
  @override
  String get todoFilter => 'छानें';
  @override
  String get todoNoTokens => 'इस सूची में कोई टोकन नहीं';
  @override
  String get todoCountOpen => 'बाकी';
  @override
  String get todoCountDone => 'पूरे';
  @override
  String get todoEmptyOpen => 'अभी कोई बाकी कार्य नहीं';
  @override
  String get todoEmptyDone => 'अभी तक कुछ पूरा नहीं';
  @override
  String get todoEmptyFiltered => 'कोई कार्य मेल नहीं खाता';
  @override
  String get todoTitle => 'कार्य';
  @override
  String get todoAddTooltip => 'कार्य जोड़ें';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'todo.txt फ़ॉर्मेट';
  @override
  String get todoHelpTooltip => 'फ़ॉर्मेट मदद';
  @override
  String get todoHelpIntro =>
      'आपके कार्य एक सादा टेक्स्ट फ़ाइल हैं, एक पंक्ति पर एक कार्य। Niman '
      'सिंटैक्स आपके लिए लिखता है, पर कुछ छिपा नहीं है: आप किसी भी '
      'एडिटर में फ़ाइल बदल सकते हैं और Niman उसे दोबारा पढ़ लेगा।';
  @override
  String get todoHelpFilesTitle => 'दो फ़ाइलें';
  @override
  String get todoHelpFilesBody =>
      'बाकी कार्य आपकी लाइब्रेरी के रूट में todo.txt में रहते हैं। '
      'कोई पूरा करने पर उसकी पंक्ति done.txt में चली जाती है, ताकि '
      'todo.txt छोटी रहे। अगर पूरी पंक्ति वापस todo.txt में आए, तो Niman '
      'अगली पढ़ाई पर उसे संग्रहीत कर देगा।';
  @override
  String get todoHelpLineTitle => 'एक पंक्ति का ढाँचा';
  @override
  String get todoHelpLineBody =>
      'वर्णन से पहले सब वैकल्पिक है और इसी क्रम में आता है:';
  @override
  String get todoHelpDoneBody =>
      'कार्य को पूरा चिह्नित करता है। चेकबॉक्स चुनने पर Niman यह जोड़ता है।';
  @override
  String get todoHelpPriority => '(A) से (Z) तक';
  @override
  String get todoHelpPriorityBody =>
      'प्राथमिकता। A सबसे ऊपर। सूची में बैज के रूप में दिखती है।';
  @override
  String get todoHelpDatesBody =>
      'पूरा करने की तारीख़, फिर बनने की तारीख़। सिर्फ़ एक तारीख़ हो तो वह '
      'बनने की है, जब तक कि पंक्ति x से शुरू न हो।';
  @override
  String get todoHelpTokensTitle => 'प्रोजेक्ट, संदर्भ और टैग';
  @override
  String get todoHelpTokensBody =>
      'वर्णन के किसी भी जगह, इनमें से किसी प्रेफ़िक्स वाला शब्द चिप बन जाता '
      'है जिससे आप छान सकते हैं। कुछ पहले से तय नहीं है: टोकन तभी बनता '
      'है जब आप उसे लिखते हैं।';
  @override
  String get todoHelpProjectBody =>
      'कार्य किसका हिस्सा है, जैसे +रसोई या +प्रबंध-thesis।';
  @override
  String get todoHelpContextBody => 'कहाँ या कैसे करेंगे, जैसे +घर या +कॉल्स।';
  @override
  String get todoHelpHashtagBody => 'खुला लेबल, जो बचे जो बाकी दो न पकड़ते।';
  @override
  String get todoHelpTagsTitle => 'तारीख़ें और रिमाइंडर';
  @override
  String get todoHelpTagsBody =>
      'ये key:value टैग हैं। Niman कार्य-डायलॉग से इन्हें लिखता है और पंक्ति '
      'में जहाँ भी हों पढ़ता है।';
  @override
  String get todoHelpDueBody =>
      'समय-सीमा वाली तारीख़। रंगीन बैज और तारीख़-छँटाई चलाती है।';
  @override
  String get todoHelpRemBody =>
      'नोटिफ़िकेशन कब भेजना है, आपकी स्थानीय समय में। स्क्रीन बंद और ऐप '
      'बंद होते हुए भी चलता है।';
  @override
  String get todoHelpRemDesktop =>
      'डेस्कटॉप पर Niman के चलने की ज़रूरत होती है जब समय आए: रिमाइंडर '
      'ऐप खुला रहने पर दिखता है, और बंद होने पर कुछ नहीं चलता।';
  @override
  String get todoHelpOtherBody =>
      'ठीक वैसे ही रखा जाता है जैसे लिखा गया, ताकि दूसरे todo.txt ऐपों के '
      'टैग यात्रा में बचें। Niman इन पर कुछ नहीं करता, rec: समेत: एक '
      'बार-बार आने वाला कार्य अभी दोहराया नहीं जाता।';
  @override
  String get todoHelpEditTitle => 'Niman के बाहर संपादन';
  @override
  String get todoHelpEditBody =>
      'जो कार्य आपने न छुआ है वह byte-दर-byte वापस लिखा जाता है, अजीब '
      'spaces समेत। एक पंक्ति बदलें और Niman सिर्फ़ उसे मानक रूप में '
      'दोबारा लिखता है, बाकी फ़ाइल को छुड़ता है।';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => 'कार्य जोड़ें';
  @override
  String get todoEditTitle => 'कार्य संपादित करें';
  @override
  String get todoDescriptionHint => 'वर्णन';
  @override
  String get todoCancel => 'रद्द करें';
  @override
  String get todoSave => 'सहेजें';
  @override
  String get todoEditAction => 'संपादित करें';
  @override
  String get todoDeleteAction => 'हटाएँ';

  // Task filters (T-TD-05).
  @override
  String get todoDueOverdue => 'मौत-देर';
  @override
  String get todoDueToday => 'आज';
  @override
  String get todoDueNext7 => 'अगले 7 दिन';
  @override
  String get todoDueNoDate => 'बिना तारीख़';
  @override
  String get todoRowDue => 'समय-सीमा';
  @override
  String get todoRowDueToday => 'आज की समय-सीमा';
  @override
  String get todoSortTooltip => 'क्रम बदलें';
  @override
  String get todoSortDue => 'समय-सीमा की तारीख़';
  @override
  String get todoSortPriority => 'प्राथमिकता';
  @override
  String get todoSortCreation => 'बनने की तारीख़';

  // Task dialog pickers (T-TD-06).
  @override
  String get todoNoPriority => 'बिना प्राथमिकता';
  @override
  String get todoNoPriorityShort => 'कोई नहीं';
  @override
  String get todoMorePriorities => 'और…';
  @override
  String get todoPriorityTitle => 'प्राथमिकता';
  @override
  String get todoNoDueDate => 'बिना समय-सीमा';
  @override
  String get todoNoReminder => 'बिना रिमाइंडर';
  @override
  String get todoAddProject => '+ प्रोजेक्ट';
  @override
  String get todoAddContext => '@ संदर्भ';
  @override
  String get todoAddHashtag => '# टैग';

  // Task reminders (T-TD-07).
  @override
  String get todoReminderChannel => 'कार्य-रिमाइंडर';
  @override
  String get todoReminderChannelDescription =>
      'रिमाइंडर-समय वाले कार्यों के लिए तय अलर्ट।';
  @override
  String get todoReminderBody => 'कार्य-रिमाइंडर';
  @override
  String get todoReminderFallbackTitle => 'कार्य-रिमाइंडर';
  @override
  String get todoReminderBlocked =>
      'नोटिफ़िकेशन बंद हैं, इसलिए रिमाइंडर नहीं दिखेंगे।';
  @override
  String get todoReminderBattery =>
      'Niman के लिए बैटरी-उपचयन चालू है। सिस्टम ऐप को सोने दे सकता है '
      'और बाकी रिमाइंडर गँवा सकता है।';
  @override
  String get todoReminderInexact =>
      'यह डिवाइस सटीक घंटी नहीं मानता, इसलिए स्क्रीन बंद होने पर '
      'रिमाइंडर कुछ मिनट देर से आ सकता है।';
  @override
  String get reminderShowTokensTitle => 'रिमाइंडर नोटिफ़िकेशन में टैग';
  @override
  String get reminderShowTokensSubtitle =>
      '+प्रोजेक्ट, @संदर्भ और #tag को नोटिफ़िकेशन-पाठ में रखें। बंद करने '
      'पर सिर्फ़ वही कार्य दिखता है जो आपने टाइप किया।';
  @override
  String get todoReminderFixAction => 'सेटिंग खोलें';
  @override
  String get todoReminderDismissAction => 'हटाएँ';
  @override
  String get todoReminderDue => 'समय-सीमा';

  // Actions and buttons shared by the dialogs (T-L10N-06).
  @override
  String get actionOk => 'ठीक है';
  @override
  String get actionCancel => 'रद्द करें';
  @override
  String get actionCreate => 'बनाएँ';
  @override
  String get actionNew => 'नया';
  @override
  String get actionSave => 'सहेजें';
  @override
  String get actionClear => 'खाली करें';
  @override
  String get actionChoose => 'चुनें';
  @override
  String get actionDelete => 'हटाएँ';
  @override
  String get actionRename => 'नाम बदलें';
  @override
  String get actionMove => 'स्थानांतरित करें';
  @override
  String get saveAndClose => 'सहेजकर बंद करें';
  @override
  String get closeUnsavedTitle => 'बिना सहेजे बदलाव';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return '«${names.first}» में अभी सहेजे न गए बदलाव हैं। '
          'बंद करने से पहले सहेजें?';
    }
    return '$names.length नोट्स में अभी सहेजे न गए बदलाव हैं। '
        'बंद करने से पहले सहेजें?';
  }

  @override
  String get closeSaveFailed => 'सहेजा नहीं जा सका; अभी भी खुला है।';
  @override
  String get actionRestore => 'पुनर्स्थापित करें';
  @override
  String get actionEmpty => 'खाली करें';

  // The shell: app bar, tabs and tree actions.
  @override
  String get hideSidebarTooltip => 'साइडबार छिपाएँ (Ctrl+B)';
  @override
  String get showSidebarTooltip => 'साइडबार दिखाएँ (Ctrl+B)';
  @override
  String get windowMinimizeTooltip => 'न्यूनतम करें';
  @override
  String get windowMaximizeTooltip => 'अधिकतम करें';
  @override
  String get windowRestoreTooltip => 'पुनर्स्थापित करें';
  @override
  String get windowCloseTooltip => 'बंद करें';
  @override
  String get tabFiles => 'फ़ाइलें';
  @override
  String get tabSearch => 'खोज';
  @override
  String get tabSettings => 'सेटिंग';
  @override
  String get quickNoteTitle => 'क्विक नोट';
  @override
  String get treeEmpty => 'अभी कोई नोट नहीं';
  @override
  String get selectANote => 'एक नोट चुनें';
  @override
  String get showListTooltip => 'सूची दिखाएँ';
  @override
  String get editRawTooltip => 'कच्चा संपादित करें';
  @override
  String get sortAscTooltip => 'A-Z क्रम';
  @override
  String get sortDescTooltip => 'Z-A क्रम';
  @override
  String get newNoteTitle => 'नया नोट';
  @override
  String get newItemTooltip => 'नया';
  @override
  String get closeMenuTooltip => 'बंद करें';
  @override
  String get newFolderTitle => 'नया फ़ोल्डर';
  @override
  String get newNoteSameFolder => 'उसी फ़ोल्डर में नया नोट';
  @override
  String get newFromTemplateSameFolder => 'उसी फ़ोल्डर में टेम्पलेट से नया';
  @override
  String trashOriginalPath(String path) => 'यहाँ था: $path';
  @override
  String get trashOriginalRoot => 'लाइब्रेरी के रूट में था';
  @override
  String trashItemCount(int count) => count == 1
      ? '1 \u0906\u0907\u091f\u092e'
      : '$count \u0906\u0907\u091f\u092e';
  @override
  String get newNoteHere => 'यहाँ नया नोट';
  @override
  String get newFolderHere => 'यहाँ नया फ़ोल्डर';
  @override
  String get newListNoteTitle => 'नया सूची-नोट';
  @override
  String get newListNoteDefault => 'मेरी सूची';
  @override
  String get setAsQuickNote => 'क्विक नोट बनाएँ';
  @override
  String get currentQuickNote => 'मौजूदा क्विक नोट';
  @override
  String get pinnedSection => 'पिन्ड';
  @override
  String pinnedSectionCount(int count) => 'पिन्ड · $count';
  @override
  String get templateFolderTitle => 'टेम्पलेट फ़ोल्डर';
  @override
  String get newFromTemplateTitle => 'टेम्पलेट से नया';
  @override
  String get newFromTemplateHere => 'यहाँ टेम्पलेट से नया';
  @override
  String get templateFormTitle => 'टेम्पलेट भरें';
  @override
  String get templateFormBacklink => 'लिंक वाला';
  @override
  String get templateFormNoNote => 'कोई नोट नहीं';
  @override
  String get templateFormPickNote => 'नोट चुनें';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => 'टेम्पलेट प्लेसहोल्डर';
  @override
  String get templateHelpSubtitle => 'दिनांक, शीर्षक और भरने वाले अन्य मान';
  @override
  String get quickNoteSubtitle => 'वह नोट जिसे त्वरित नोट टैब खोलता है';
  @override
  String get listFolderSubtitle => 'नई कार्य सूचियाँ';
  @override
  String get templateFolderSubtitle => 'टेम्पलेट से नया का स्रोत';
  @override
  String get attachmentsFolderSubtitle => 'नोट में डाली गई छवियाँ और ऑडियो';
  @override
  String get templateHelpIntro =>
      'टेम्पलेट एक सादा नोट है जिसमें छेद हैं। टेम्पलेट से नोट बनाना '
      'उसका टेक्स्ट कॉपी करता है और छेद भर देता है।';
  @override
  String get templateHelpUnknown =>
      'जो प्लेसहोल्डर Niman नहीं जानता वह ठीक वैसे ही रहता है, ताकि '
      'टाइपिंग-ग़लती नोट में दिखे, किसी पंक्ति को चुपचाप निगलने की बजाय।';
  @override
  String get templateHelpValuesTitle => 'मान';
  @override
  String get templateHelpTitleBody => 'नाम जिसके तहत नोट बन रहा है।';
  @override
  String get templateHelpDateBody =>
      'आज, और अभी का समय। दोनों को फ़ॉर्मेट ले सकते हैं: '
      '{{date:DD/MM/YYYY}}।';
  @override
  String get templateHelpNowBody => 'तारीख़ और समय साथ।';
  @override
  String get templateHelpUuidBody => 'एक नया पहचान-चिह्न, हर बार अलग।';
  @override
  String get templateHelpCounterBody =>
      'एक संख्या जो नाम-दर-नाम बढ़ती है और रीस्टार्ट के बाद भी रहती है: '
      'पहला नोट 1 लिखता है, अगला 2। एक नोट में वही नाम वही संख्या '
      'लिखता है; |pad:3 के साथ जोड़ें।';
  @override
  String get templateHelpCursorBody =>
      'नोट बनने पर यहाँ कर्सर रखता है; चिह्न स्वयं नहीं लिखा जाता। '
      'पहला चिह्न जीतता है, कोई छँटाई नहीं, सिर्फ़ नए नोट — और ऑटो-फ़ोकस '
      'बंद होने पर भी कीबोर्ड खुलता है।';
  @override
  String get templateHelpDatesTitle => 'तारीख़ लिखना';
  @override
  String get templateHelpDatesBody =>
      'ये फ़ॉर्मेट के अंदर तारीख़ के हिस्से के लिए हैं। बाकी सब '
      'अक्षरशः है, और एकल-कोट में टेक्स्ट भी। महीने और दिन के नाम '
      'ऐप की भाषा के अनुसार होते हैं।';
  @override
  String get templateHelpYear => 'साल: 2026, 26';
  @override
  String get templateHelpMonth => 'महीना: 03, 3, मार्च, Mar';
  @override
  String get templateHelpDay => 'दिन: 09, 9, सोमवार, Mon';
  @override
  String get templateHelpTime => 'घंटे, मिनट, सेकंड';
  @override
  String get templateHelpWeek => 'ISO सप्ताह और तिमाही: 11, 11, 1';
  @override
  String get templateHelpFiltersTitle => 'फ़िल्टर';
  @override
  String get templateHelpFiltersBody =>
      'मान के बाद फ़िल्टर आ सकते हैं, बाएँ से दाएँ लागू होते हैं।';
  @override
  String get templateHelpCaseBody =>
      'अक्षर बड़े, छोटे, और हर शब्द का पहला अक्षर — जो शब्द आपने '
      'खुद बड़ा किया वह वैसा ही रहता है।';
  @override
  String get templateHelpSlugBody =>
      'टेक्स्ट का लिंक-रूप, विकिलिंक बनाने के लिए।';
  @override
  String get templateHelpPadBody =>
      'सिरों के spaces हटाएँ; किसी चौड़ाई तक शून्य भरें; खाली होने पर '
      'रीफ़ॉलबक दें।';
  @override
  String get templateHelpShiftBody =>
      'तारीख़ को दिन, सप्ताह, महीने या साल से खिसकाएँ — आने वाले सप्ताह की '
      'लेक्चर, पिछले महीने की फ़ाइल।';
  @override
  String get templateHelpSnapBody =>
      'तारीख़ को उसके सप्ताह, महीने या साल की शुरुआत या अंत पर लगाएँ।';
  @override
  String get templateHelpAskTitle => 'कुछ पूछना';
  @override
  String get templateHelpAskBody =>
      'नोट बनने से पहले एक फ़ॉर्म आता है, हर सवाल के लिए एक बॉक्स — '
      'और बैकलिंक के लिए एक, जब टेम्पलेट चाहता हो। वही लेबल दो बार '
      'एक सवाल है, और उसका जवाब हर जगह भरता है — फ़ोल्डर और फ़ाइल-नाम '
      'समेंत।';
  @override
  String get templateHelpAskFieldBody =>
      'टाइप करने के लिए बॉक्स; दूसरे कॉलन के बाद टेक्स्ट वह है जिससे '
      'यह शुरू होता है।';
  @override
  String get templateHelpChoiceBody => 'सूची से एक चयन, विराम-चिह्न से अलग।';
  @override
  String get templateHelpWhereTitle => 'नोट कहाँ जाता है';
  @override
  String get templateHelpWhereBody =>
      'ये टेक्स्ट नहीं, निर्देश हैं, और टेम्पलेट के अपने फ़्रंटमैटर में '
      'niman: ब्लॉक में रहते हैं। ब्लॉक चलते ही हटा दिया जाता है, '
      'इससे वह कभी नोट में नहीं आता। इनके मानों में प्लेसहोल्डर हो सकते '
      'हैं।';
  @override
  String get templateHelpFolderBody =>
      'फ़ोल्डर जिसमें नोट बनता है, न हो तो बनाया जाता है। उसके बिना नोट '
      'वहीं आता है जहाँ आप थे।';
  @override
  String get templateHelpFilenameBody =>
      'नोट का नाम। जो टेम्पलेट यह कहता है उसे नाम पूछा नहीं जाता।';
  @override
  String get templateHelpAppendBody =>
      'नोट पहले से हो तो उसमें जोड़ें, दूसरा बनाने की बजाय। यही '
      'महीने भर की बैठकों को एक फ़ाइल बनाता है।';
  @override
  String get templateHelpOpenBody =>
      'नोट हो जाने पर क्या होता है: एडिटर (डिफ़ॉल्ट), पूर्वावलोकन, या '
      'कुछ नहीं — नोट फ़ाइल हो जाता है और आप जहाँ थे वहीं रहते हैं।';
  @override
  String get templateHelpAroundTitle => 'कहाँ से आया';
  @override
  String get templateHelpParentBody =>
      'वो नोट जो आप फ़ॉर्म में चुनते हैं, जो स्क्रीन पर वाले की सलाह देता '
      'है; वापस लिंक के लिए [[{{parent}}]] लिखें।';
  @override
  String get templateHelpFolderValueBody => 'वो फ़ोल्डर जहाँ नोट आ गया।';
  @override
  String get templateHelpClipboardBody =>
      'क्लिपबोर्ड में क्या है, और एडिटर-चयन जब नोट किसी और से शुरू हो।';
  @override
  String get templateHelpIncludeTitle => 'एक टुकड़ा फिर से इस्तेमाल करना';
  @override
  String get templateHelpIncludeBody =>
      'दूसरा टेम्पलेट चिपकाता है, ताकि दस टेम्पलेट एक चेकलिस्ट साझा '
      'कर सकें। पहले टेम्पलेट-फ़ोल्डर में ढूँढा जाता है, और .md छोड़ा '
      'जा सकता है। उसके अपने सवाल उसी फ़ॉर्म में जुड़ते हैं।';
  @override
  String get templateHelpExampleTitle => 'सब साथ में';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ कोई टेम्पलेट नहीं «$path»';
  @override
  String includeCycle(String path) => '⚠ «$path» स्वयं को शामिल करता है';
  @override
  String includeTooDeep(String path) => '⚠ «$path» बहुत गहरे तक जड़ा है';
  @override
  String frontmatterInvalid(String reason) =>
      'फ़्रंटमैटर नहीं पढ़ा गया: $reason';
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      '«$template» का फ़्रंटमैटर नहीं पढ़ा गया, इसलिए उसका फ़ोल्डर और '
      'फ़ाइल-नाम कुछ नहीं कर पाए: $reason';
  @override
  String get templatePickerTitle => 'एक टेम्पलेट चुनें';
  @override
  String templatePickerEmpty(String folder) =>
      'अभी कोई टेम्पलेट नहीं। $folder/ में नोट रखें और वह बन जाएगा।';

  // Tree actions.
  @override
  String get actionPin => 'पिन करें';
  @override
  String get actionUnpin => 'पिन हटाएँ';
  @override
  String get pinToWidget => 'होम विजेट में पिन करें';
  @override
  String get pinnedForWidget =>
      'पिन हो गया: अब नोट विजेट को होम स्क्रीन पर रखें';
  @override
  String get pinWidgetUnavailable => 'होम-स्क्रीन विजेट Android पर उपलब्ध हैं';

  // Handing a note's file to the OS (issue #76).
  @override
  String get openInFileManager => 'फ़ाइल प्रबंधक में दिखाएँ';
  @override
  String get openInDefaultApp => 'डिफ़ॉल्ट ऐप में खोलें';
  @override
  String get newNoteTabTooltip => 'नए टैब में नया नोट';
  @override
  String get openNotesTooltip => 'खुले नोट';
  @override
  String get closeTabTooltip => 'बंद करें';
  @override
  String get openInNewTab => 'नए टैब में खोलें';
  @override
  String get splitRight => 'दाईं ओर बाँटें';
  @override
  String get splitDown => 'नीचे बाँटें';
  @override
  String get moveToOtherPane => 'दूसरे पैन में ले जाएँ';
  @override
  String get openBeside => 'बगल में खोलें';
  @override
  String get closeAllNotes => 'सभी बंद करें';
  @override
  String get sidePanelTooltip => 'साइड पैनल दिखाएँ या छिपाएँ';
  @override
  String get historyAllVersions => 'सभी संस्करण';
  @override
  String get commandPaletteTitle => 'कमांड पैलेट';
  @override
  String get goToNoteTitle => 'नोट पर जाएँ';
  @override
  String get paletteGroupNote => 'नोट';
  @override
  String get paletteGroupEditor => 'एडिटर';
  @override
  String get paletteGroupView => 'दृश्य';
  @override
  String get paletteGroupLibrary => 'लाइब्रेरी';
  @override
  String get paletteGroupGoTo => 'जाएँ';
  @override
  String get paletteGroupJournal => 'डायरी';
  @override
  String get journalToday => 'आज की प्रविष्टि';
  @override
  String get journalPrevious => 'पिछली प्रविष्टि';
  @override
  String get journalNext => 'अगली प्रविष्टि';
  @override
  String get commandNeedJournalEntry => 'खुली डायरी प्रविष्टि चाहिए';
  @override
  String journalCreateAsk(String day) =>
      '$day के लिए अभी कोई प्रविष्टि नहीं है। बनाएँ?';
  @override
  String journalTemplateMissing(String path) =>
      'डायरी टेम्पलेट $path पढ़ा नहीं जा सका: प्रविष्टि उसके बिना बनाई गई।';
  @override
  String get commandsTitle => 'कमांड';
  @override
  String get commandsIntro =>
      'कमांड पैलेट केवल वे कमांड दिखाता है जो आप जहाँ हैं वहाँ चल सकते हैं। '
      'यहाँ सभी हैं, और यह भी कि हर एक कब दिखता है।';
  @override
  String get commandNeedNone => 'हमेशा उपलब्ध';
  @override
  String get commandNeedOpenNote => 'खुला नोट चाहिए';
  @override
  String get commandNeedWideWindow => 'केवल चौड़ी विंडो में';
  @override
  String get commandNeedDockRoom =>
      'साइड पैनल के लिए पर्याप्त चौड़ी विंडो चाहिए';
  @override
  String get commandNeedDesktop => 'केवल डेस्कटॉप पर';
  @override
  String get commandNeedNotInZen => 'ज़ेन मोड में नहीं';
  @override
  String get commandNeedZenRoom => 'डेस्कटॉप, किसी टैब में खुले नोट के साथ';
  @override
  String get commandNeedPreview => 'पूर्वावलोकन चालू होने पर, टेक्स्ट नोट पर';
  @override
  String get commandNeedTwoEditors => 'दोनों एडिटर चालू होने पर';
  @override
  String get paletteHint => 'कमांड और नोट खोजें';
  @override
  String get paletteNoResults => 'कुछ नहीं मिला';
  @override
  String get paletteCommands => 'कमांड';
  @override
  String get paletteNotes => 'नोट';
  @override
  String get paletteFooter =>
      '↑↓ चलने के लिए · ↵ चुनने के लिए · esc बंद करने के लिए';
  @override
  String get paletteFooterTouch =>
      'उपयोग के लिए टैप करें · पिन इसे ऊपर रखती है';
  @override
  String get palettePinned => 'पिन किए';
  @override
  String get palettePin => 'पिन करें';
  @override
  String get paletteUnpin => 'हटाएँ';
  @override
  String get palettePinFooter => 'पिन करने के लिए alt+P';
  @override
  String get spellCheckScanning => 'नोट जाँचा जा रहा है…';
  @override
  String get spellCheckAgain => 'फिर से जाँचें';
  @override
  String spellCheckCapped(int count) =>
      'पहले $count दिखाए गए हैं: कुछ ठीक करें, फिर बाकी के लिए फिर से जाँचें';
  @override
  String get dropHint =>
      'खोलने के लिए Markdown फ़ाइलें छोड़ें, या आयात करने के लिए फ़ोल्डर';
  @override
  String get dropNothing => 'डेस्कटॉप ने उस ड्रॉप के लिए कोई फ़ाइल नहीं दी।';
  @override
  String get importFolderAction => 'आयात करें';
  @override
  String dropRejected(String names) =>
      'यहाँ केवल Markdown फ़ाइलें और फ़ोल्डर खुलते हैं: $names';
  @override
  String importFolderTitle(String name) => '“$name” आयात करें?';
  @override
  String importFolderBody(int count) =>
      'इसकी Markdown फ़ाइलें ($count) लाइब्रेरी के नए फ़ोल्डर में कॉपी होती '
      'हैं। छोड़ा गया फ़ोल्डर जैसा है वैसा रहता है।';
  @override
  String importFolderDone(String folder) => '$folder में आयात किया गया';
  @override
  String importFolderEmpty(String name) => '$name में कोई Markdown फ़ाइल नहीं';
  @override
  String get openFileTitle => 'फ़ाइल खोलें';
  @override
  String get outsideFileNote =>
      'किसी लाइब्रेरी से बाहर: जहाँ है वहीं सहेजी जाती है, इंडेक्स नहीं, '
      'इतिहास नहीं, लिंक नहीं खुलते';
  @override
  String get typewriterOn => 'टाइपराइटर मोड चालू करें';
  @override
  String get typewriterOff => 'टाइपराइटर मोड बंद करें';
  @override
  String get typewriterTitle => 'टाइपराइटर मोड';
  @override
  String get formatNoteTitle => 'मार्कडाउन व्यवस्थित करें';
  @override
  String get formatNoteDone => 'नोट व्यवस्थित कर दिया गया।';
  @override
  String get formatNoteAlreadyTidy => 'नोट पहले से व्यवस्थित था।';
  @override
  String get typewriterSubtitle =>
      'जिस पंक्ति पर आप लिख रहे हैं उसे एडिटर के बीच में रखें';
  @override
  String get zenMode => 'ज़ेन मोड';
  @override
  String get zenModeEnter => 'ज़ेन मोड में जाएँ';
  @override
  String get zenModeLeave => 'ज़ेन मोड से बाहर निकलें';
  @override
  String get keySpace => 'स्पेस';
  @override
  String get keyEnter => 'एंटर';
  @override
  String get keyTab => 'टैब';
  @override
  String get keyEscape => 'Esc';
  @override
  String get keyBackspace => 'बैकस्पेस';
  @override
  String get keyDelete => 'डिलीट';
  @override
  String get keyArrowUp => 'ऊपर';
  @override
  String get keyArrowDown => 'नीचे';
  @override
  String get keyArrowLeft => 'बाएँ';
  @override
  String get keyArrowRight => 'दाएँ';
  @override
  String get keyHome => 'होम';
  @override
  String get keyEnd => 'एंड';
  @override
  String get keyPageUp => 'पेज अप';
  @override
  String get keyPageDown => 'पेज डाउन';
  @override
  String get keyInsert => 'इंसर्ट';
  @override
  String get shortcutNone => 'कोई शॉर्टकट नहीं';
  @override
  String get shortcutRestoreDefaults => 'डिफ़ॉल्ट बहाल करें';
  @override
  String get shortcutRestoreDefaultsConfirm =>
      'सभी शॉर्टकट वैसे ही वापस करें जैसे Niman देता है?';
  @override
  String get shortcutRevert => 'डिफ़ॉल्ट पर वापस';
  @override
  String get shortcutClear => 'शॉर्टकट हटाएँ';
  @override
  String get shortcutCapturePrompt =>
      'कुंजियाँ दबाएँ। Esc और Tab भी दर्ज होते हैं: बाहर निकलने के लिए रद्द '
      'करें।';
  @override
  String get shortcutCaptureNeedsModifier =>
      'Ctrl, Alt या Meta जोड़ें: अकेली कुंजी टाइप करने के लिए है।';
  @override
  String get shortcutMove => 'इसे ले जाएँ';
  @override
  String get shortcutUseAnyway => 'फिर भी उपयोग करें';
  @override
  String get shortcutUndo => 'पूर्ववत करें';
  @override
  String get shortcutRedo => 'फिर से करें';
  @override
  String get shortcutChange => 'शॉर्टकट बदलें';
  @override
  String shortcutCaptureTitle(String command) => '$command के लिए कुंजियाँ';
  @override
  String shortcutConflict(String keys, String other) =>
      '$keys पहले से $other का है। इसे यहाँ ले जाएँ? $other बिना शॉर्टकट के '
      'रहेगा।';
  @override
  String shortcutTakesEditorKey(String keys, String what) =>
      '$keys टेक्स्ट फ़ील्ड और एडिटर में $what भी है। वहाँ आपका कमांड इसे ले '
      'लेगा।';
  @override
  String get openFileMissing => 'इस नोट की फ़ाइल डिस्क पर नहीं है';
  @override
  String get openFileFailed => 'यह नोट Niman के बाहर नहीं खुल सका';

  @override
  String get movedToTrash => 'ट्रैश में गया';
  @override
  String get deletedMessage => 'हटाया गया';
  @override
  String deleteToTrashConfirm(String name) => '$name को .trash/ में भेजा जाएगा';
  @override
  String deleteForeverConfirm(String name) =>
      '$name को हमेशा के लिए हटाया जाएगा';
  @override
  String get chooseDestination => 'गंतव्य चुनें';
  @override
  String get libraryRoot => 'लाइब्रेरी-रूट';
  @override
  String moveTitle(String name) => '$name स्थानांतरित करें';
  @override
  String headingLevelLabel(int level) => 'हेडिंग स्तर $level';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty =>
      'अभी कोई क्विक नोट नहीं। मौजूदा नोट चुनें या नया बनाएँ — क्विक नोट '
      'यहीं खुलेगा।';
  @override
  String get quickNoteChooseAction => 'एक नोट चुनें…';
  @override
  String get quickNoteCreateAction => 'नया नोट बनाएँ…';
  @override
  String get quickNoteNewTitle => 'नया क्विक नोट';
  @override
  String get quickNotePickerTitle => 'क्विक नोट चुनें';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => 'नया फ़ोल्डर';
  @override
  String get folderPickerEmpty => 'अभी कोई फ़ोल्डर नहीं';
  @override
  String get listFolderTitle => 'सूची-फ़ोल्डर';
  @override
  String get attachmentsFolderTitle => 'अनुलग्नक फ़ोल्डर';

  // Trash (M1).
  @override
  String get trashEmpty => 'ट्रैश खाली है';
  @override
  String get trashEmptyAction => 'ट्रैश खाली करें';
  @override
  String get trashEmptyConfirm =>
      'यह ट्रैश-फ़ोल्डर की सब चीज़ें हमेशा के लिए हटा देता है, Niman की '
      'रखी-न-रखी समेत।';
  @override
  String trashDeleteConfirm(String name) =>
      '$name को हमेशा के लिए हटाया जाएगा (पुनर्स्थापना नहीं)';
  @override
  String get trashDeletePermanently => 'हमेशा के लिए हटाएँ';

  // The open/create library screen.
  @override
  String get openLibraryIntro =>
      'Markdown नोट्स का फ़ोल्डर अपनी लाइब्रेरी के रूप में खोलें';
  @override
  String get openLibraryExisting => 'मौजूदा खोलें';
  @override
  String get openLibraryCreate => 'नया बनाएँ';
  @override
  String get openLibraryCreateTitle => 'नई लाइब्रेरी बनाएँ';
  @override
  String get openLibraryFolderName => 'फ़ोल्डर का नाम';
  @override
  String get openLibraryChooseFolder => 'लाइब्रेरी-फ़ोल्डर चुनें';
  @override
  String get openLibraryChooseParent =>
      'वह फ़ोल्डर चुनें जिसमें लाइब्रेरी बनेगी';
  @override
  String get openLibraryUnsupported =>
      'यह फ़ोल्डर समर्थित नहीं है। डिवाइस-स्टोरेज का कोई फ़ोल्डर चुनें।';
  @override
  String indexingCount(int done, int total) => '$done / $total नोट्स';

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => 'आपकी लाइब्रेरी';
  @override
  String get libraryUnreachable => 'पहुँचा नहीं जा सका';
  @override
  String get libraryOpenedToday => 'आज खुली';
  @override
  String get libraryOpenedYesterday => 'कल खुली';
  @override
  String libraryOpenedDaysAgo(int days) => '$days दिन पहले खुली';
  @override
  String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return '${when.year}/$m/$d को खुली';
  }

  @override
  String get libraryOpenNow => 'अभी खोलें';
  @override
  String get switchLibraryTitle => 'लाइब्रेरी बदलें';
  @override
  String get libraryForget => 'भूल जाएँ';
  @override
  String libraryForgetTitle(String name) => '«$name» भूलें?';
  @override
  String get libraryForgetExplained =>
      'वह इस सूची से जाती है। फ़ोल्डर, नोट्स और लाइब्रेरी-सेटिंग वहीं '
      'रहती हैं, और फिर खोलने पर वह लौट आती है।';

  // Android storage access.
  @override
  String get storageAccessAction => 'फ़ाइल-प्रवेश दें';
  @override
  String get storageAccessNeeded =>
      '«सभी फ़ाइलों के प्रवेश» के बिना Niman आपके नोट्स नहीं पढ़ सकता। '
      'लाइब्रेरी खोलने के लिए दें।';
  @override
  String get storageAccessExplained =>
      'Niman नोट्स को सादे फ़ाइलें मानकर पढ़ता है, इसलिए Android को '
      'सभी फ़ाइलों का प्रवेश देना होगा। कुछ अपलोड नहीं होता, और सिर्फ़ '
      'वही लाइब्रेरी-फ़ोल्डर पढ़ा जाता है जो आप चुनें।';
  @override
  String folderAccessDenied(Object error) =>
      'सिस्टम ने फ़ोल्डर का प्रवेश नहीं दिया: $error';
  @override
  String folderPickFailed(Object error) => 'फ़ोल्डर नहीं चुना जा सका: $error';

  // Settings screen rows and messages.
  @override
  String get settingsTitle => 'सेटिंग';
  @override
  String get libraryPathTitle => 'लाइब्रेरी-पाथ';
  @override
  String get reindexTitle => 'अभी दोबारा इंडेक्स करें';
  @override
  String get reindexDone => 'दोबारा इंडेक्स पूरा';
  @override
  String get closeLibraryTitle => 'लाइब्रेरी बंद करें';
  @override
  String get exportLogTitle => 'डिबग-लॉग निर्यात करें';
  @override
  String get exportLogSubtitle => 'दर्ज घटनाओं को आपके चुने फ़ाइल में सहेजें';
  @override
  String get exportLogEmpty => 'डिबग-लॉग बफ़र खाली है';
  @override
  String get quickNoteUnset => 'अभी तय नहीं';
  @override
  String exportLogDone(Object target) =>
      'डिबग-लॉग $target में निर्यात किया गया';
  @override
  String exportLogFailed(Object error) => 'निर्यात विफल: $error';

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) => '«$term» का पूरा-शब्द मेल नहीं मिला';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      '«$term» के $occurrences स्थान $notes नोट्स में बदले गए';
  @override
  String replaceSkipped(int skipped) => ' ($skipped खुले नोट छोड़े गए)';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      '«$term» का कोई सटीक पूरा-शब्द मेल नहीं '
      '${only == null ? 'मिला' : '$only में मिला'}';

  // About (issue #80).
  @override
  String get settingsSectionAbout => 'परिचय';
  @override
  String get versionTitle => 'संस्करण';
  @override
  String get changelogTitle => 'बदलावों की सूची';
  @override
  String get changelogEmpty => 'कोई बदलाव दर्ज नहीं';
  @override
  String changelogWhatsNew(String version) =>
      'संस्करण $version में क्या नया है';

  // Note history (issues #13, #55, #67).
  @override
  String get noteHistoryTitle => 'इतिहास';
  @override
  String get noteMenuTooltip => 'नोट क्रियाएँ';
  @override
  String get historyCurrentVersion => 'मौजूदा संस्करण';
  @override
  String get historyCurrentSubtitle => 'नोट जैसा अभी है';
  @override
  String get historyToday => 'आज';
  @override
  String get historyYesterday => 'कल';
  @override
  String get historyReasonSession => 'संपादन से पहले';
  @override
  String get historyReasonInterval => 'संपादन के दौरान';
  @override
  String get historyReasonRestore => 'पुनर्स्थापना से पहले';
  @override
  String get historyReasonSync => 'सिंक से पहले';
  @override
  String get historyReasonReplace => 'बदलने से पहले';
  @override
  String get historyReasonUnknown => 'पुनर्प्राप्त';
  @override
  String get historySyncBase => 'सिंक आधार';
  @override
  String get historyEmpty =>
      'अभी कोई संस्करण नहीं। नोट संपादित करना शुरू करने पर Niman एक '
      'संस्करण रखता है, फिर लिखते समय हर कुछ मिनट में अधिकतम एक।';
  @override
  String historyKept(int kept, int limit) =>
      '$limit में से $kept संस्करण रखे गए';
  @override
  String get historyBaseKept =>
      'सिंक आधार सीमा से अधिक होने पर भी रखा जाता है।';
  @override
  String get historyOff =>
      'इस लाइब्रेरी के लिए इतिहास बंद है (सेटिंग, लाइब्रेरी)।';
  @override
  String get historyLoadFailed => 'इतिहास नहीं पढ़ा जा सका';
  @override
  String get historyCompareSubtitle => 'मौजूदा संस्करण से तुलना';
  @override
  String get historyTabChanges => 'बदलाव';
  @override
  String get historyTabVersion => 'संस्करण';
  @override
  String get historyNoChanges => 'पाठ मौजूदा संस्करण जैसा ही है।';
  @override
  String get historyRestoreAction => 'यह संस्करण पुनर्स्थापित करें';
  @override
  String historyRestoreConfirmTitle(String when) =>
      '$when का संस्करण पुनर्स्थापित करें?';
  @override
  String get historyRestoreConfirmBody =>
      'मौजूदा पाठ पहले इतिहास में रखा जाता है, इसलिए आप कभी भी वापस जा '
      'सकते हैं।';
  @override
  String get historyRestoreConfirm => 'पुनर्स्थापित करें';
  @override
  String historyRestored(String when) =>
      '$when का संस्करण पुनर्स्थापित किया गया';
  @override
  String get historyRestoreFailed => 'संस्करण पुनर्स्थापित नहीं किया जा सका';
  @override
  String get actionUndo => 'पूर्ववत करें';
  @override
  String diffLineRange(int start, int end) => 'पंक्तियाँ $start–$end';
  @override
  String diffLineSingle(int line) => 'पंक्ति $line';
  @override
  String diffUnchanged(int count) =>
      count == 1 ? '1 अपरिवर्तित पंक्ति' : '$count अपरिवर्तित पंक्तियाँ';
  @override
  String get historyTakeHunk => 'यहाँ पुनर्स्थापित करें';
  @override
  String historyRestoreSelectedAction(int count) => count == 1
      ? '1 बदलाव पुनर्स्थापित करें'
      : '$count बदलाव पुनर्स्थापित करें';
  @override
  String get historyRestoreSelectedConfirmBody =>
      'चुने गए बदलाव इस संस्करण के पाठ पर लौट जाते हैं। नोट जैसा अभी है, पहले '
      'एक संस्करण के रूप में रखा जाता है, इसलिए आप इसे पूर्ववत कर सकते हैं।';
  @override
  String get historyNoteChangedReloaded =>
      'आप यहाँ थे तब नोट बदल गया — तुलना ताज़ा कर दी गई है।';
  @override
  String get historyVersionsTitle => 'कितने संस्करण रखें';
  @override
  String get historyVersionsSubtitle => 'प्रति नोट, .history/ में';
  @override
  String historyVersionsValue(int count) => count == 0 ? 'कोई नहीं' : '$count';
  @override
  String get historyIntervalTitle => 'नए संस्करणों के बीच कम से कम';
  @override
  String get historyIntervalSubtitle =>
      'लिखते समय; नोट संपादित करना शुरू करने पर एक संस्करण हमेशा रखा जाता है';
  @override
  String historyIntervalValue(int minutes) => '$minutes मिनट';
  @override
  String get settingsSectionTranscription => 'ट्रांसक्रिप्शन';
  @override
  String get transcriptionModelTitle => 'मॉडल';
  @override
  String get transcriptionModelNone => 'कोई नहीं';
  @override
  String get transcriptionLanguageTitle => 'भाषा';
  @override
  String get transcriptionLanguageSubtitle =>
      'आपकी रिकॉर्डिंग में बोली गई भाषा। इसे चुनना अपने आप पहचानने से ज़्यादा '
      'सटीक है।';
  @override
  String transcriptionLanguageApp(String language) => 'ऐप जैसी ($language)';
  @override
  String get transcriptionLanguageDetect => 'अपने आप पहचानें';
  @override
  String get transcriptionModelsTitle => 'ट्रांसक्रिप्शन मॉडल';
  @override
  String transcriptionModelsUsed(String size) => '$size इस्तेमाल में';
  @override
  String get transcriptionModelsInstalled => 'डाउनलोड किए गए';
  @override
  String get transcriptionModelsDownloading => 'डाउनलोड हो रहे हैं';
  @override
  String get transcriptionModelsAvailable => 'उपलब्ध';
  @override
  String get transcriptionModelsFooter =>
      'मॉडल इस डिवाइस पर ऐप के स्टोरेज में रहते हैं। वे लाइब्रेरी में कॉपी या '
      'सिंक नहीं किए जाते।';
  @override
  String get transcriptionModelDefault => 'डिफ़ॉल्ट';
  @override
  String get transcriptionModelSlow => 'धीमा';
  @override
  String get transcriptionModelHintTiny => 'सबसे तेज़, सबसे कम सटीक';
  @override
  String get transcriptionModelHintBase => 'गति और सटीकता का अच्छा संतुलन';
  @override
  String get transcriptionModelHintSmall => 'ज़्यादा सटीक, लगभग 3× धीमा';
  @override
  String get transcriptionModelHintMedium => 'बहुत सटीक, फ़ोन पर धीमा';
  @override
  String get transcriptionModelHintLarge => 'सबसे सटीक, बहुत मेमोरी चाहिए';
  @override
  String get transcriptionModelDownload => 'डाउनलोड करें';
  @override
  String transcriptionModelDeleteTitle(String model) => '$model मॉडल हटाएँ?';
  @override
  String transcriptionModelDeleteBody(String size) =>
      'इससे $size खाली होगा। आप बाद में मॉडल फिर से डाउनलोड कर सकते हैं।';
  @override
  String get transcriptionModelFailed =>
      'डाउनलोड नहीं हो सका। कनेक्शन जाँचें और फिर से कोशिश करें।';
  @override
  String get actionRetry => 'फिर से कोशिश करें';
  @override
  String get decimalSeparator => '.';
  @override
  String get transcriptionModelRetrying =>
      'कनेक्शन टूट गया, फिर से कोशिश हो रही है…';
  @override
  String transcriptionModelInterrupted(String progress) =>
      '$progress पर रुका हुआ';
  @override
  String get actionResume => 'फिर शुरू करें';
  @override
  String get audioTranscribe => 'ट्रांसक्राइब करें';
  @override
  String get audioTranscribeUnsupported => 'इस डिवाइस पर केवल WAV रिकॉर्डिंग';
  @override
  String get transcriptionQueued => 'कतार में';
  @override
  String get transcriptionPreparing => 'ऑडियो तैयार हो रहा है…';
  @override
  String transcriptionRunning(int percent) =>
      'ट्रांसक्राइब हो रहा है… $percent%';
  @override
  String transcriptionWaitingForModel(String model, int percent) =>
      '$model डाउनलोड हो रहा है · $percent%';
  @override
  String get transcriptionSaved => 'ट्रांसक्रिप्शन विवरण में जोड़ दिया गया';
  @override
  String get transcriptionNoSpeech =>
      'इस रिकॉर्डिंग में कोई बोली नहीं पहचानी गई';
  @override
  String get transcriptionFailed => 'ट्रांसक्रिप्शन नहीं हो सका';
  @override
  String get transcriptionPickModelTitle => 'मॉडल चुनें';
  @override
  String get transcriptionPickModelBody =>
      'ट्रांसक्रिप्शन इसी डिवाइस पर होता है और रिकॉर्डिंग कभी अपलोड नहीं '
      'होती। मॉडल एक ही बार डाउनलोड होता है।';
  @override
  String get transcriptionPickModelAction =>
      'डाउनलोड करें और ट्रांसक्राइब करें';
  @override
  String get transcriptionModelRecommended => 'सुझाया गया';
  @override
  String get transcriptionExistingTitle => 'इस रिकॉर्डिंग का विवरण पहले से है';
  @override
  String get transcriptionExistingBody =>
      'इसे ट्रांसक्रिप्शन से बदलें या ट्रांसक्रिप्शन नीचे जोड़ें?';
  @override
  String get transcriptionAppend => 'नीचे जोड़ें';
  @override
  String get transcriptionReplace => 'बदलें';
  @override
  String get settingsSectionSync => 'सिंक';
  @override
  String get syncWebDavTitle => 'WebDAV';
  @override
  String get syncNotConfigured => 'इस लाइब्रेरी के लिए सेट नहीं है';
  @override
  String get syncNeverSynced => 'कभी सिंक नहीं हुआ';
  @override
  String syncLastSynced(String when) => 'सिंक किया गया: $when';
  @override
  String get syncRunning => 'सिंक हो रहा है…';
  @override
  String syncScreenSubtitle(String library) => 'लाइब्रेरी $library';
  @override
  String get syncUrlLabel => 'फ़ोल्डर का पता';
  @override
  String get syncUrlRequired => 'सर्वर का पता दर्ज करें';
  @override
  String get syncUrlHint =>
      'फ़ोल्डर पहले से मौजूद होना चाहिए। पता वैसे ही कॉपी करें '
      'जैसे सर्वर उसे दिखाता है।';
  @override
  String get syncHttpWarning =>
      'बिना एन्क्रिप्शन का कनेक्शन: VPN पर या आपके लोकल नेटवर्क '
      'में ठीक है।';
  @override
  String get syncUserLabel => 'उपयोगकर्ता';
  @override
  String get syncUserHint =>
      'अगर सर्वर क्रेडेंशियल नहीं माँगता, तो खाली छोड़ें।';
  @override
  String get syncPasswordLabel => 'पासवर्ड';
  @override
  String get syncPasswordHint =>
      'इस डिवाइस के कीचेन में रखा जाता है, लाइब्रेरी की फ़ाइलों '
      'में कभी नहीं।';
  @override
  String get syncPasswordKeepHint =>
      'सहेजा गया पासवर्ड रखने के लिए खाली छोड़ें।';
  @override
  String get syncShowPassword => 'पासवर्ड दिखाएँ';
  @override
  String get syncHidePassword => 'पासवर्ड छिपाएँ';
  @override
  String get syncTestAction => 'कनेक्शन जाँचें';
  @override
  String get syncTesting => 'जाँच हो रही है…';
  @override
  String get syncRetargetWarning =>
      'नया पता या उपयोगकर्ता होने पर अगला सिंक पहले सिंक की तरह '
      'फिर से शुरू होगा।';
  @override
  String get syncTestOk => 'कनेक्शन काम कर रहा है';
  @override
  String get syncModeFull => 'पूर्ण मोड';
  @override
  String get syncModeCompatible => 'संगत मोड';
  @override
  String syncTestOkSubtitle(String mode, int ms) => '$mode · $ms ms';
  @override
  String get syncCapBasic => 'पढ़ना, लिखना और हटाना';
  @override
  String get syncCapEtags => 'फ़ाइल फ़िंगरप्रिंट (ETag)';
  @override
  String get syncCapNoEtags => 'फ़ाइल फ़िंगरप्रिंट (ETag) नहीं';
  @override
  String get syncCapNoEtagsDetail =>
      'आकार और तारीख़ की तुलना होती है; शक होने पर फिर से '
      'डाउनलोड होता है';
  @override
  String get syncCapGuarded => 'सुरक्षित लेखन';
  @override
  String get syncCapUnguarded => 'असुरक्षित लेखन';
  @override
  String get syncCapUnguardedDetail =>
      'लिखने से ठीक पहले सर्वर पर फ़ाइल जाँची जाती है';
  @override
  String get syncCapMove => 'दोबारा अपलोड किए बिना नाम बदलना';
  @override
  String get syncCapNoMove => 'सर्वर पर नाम नहीं बदला जा सकता';
  @override
  String get syncCapNoMoveDetail =>
      'नाम बदलना एक हटाना और नया अपलोड बन जाता है';
  @override
  String get syncCompatibleNote =>
      'संगत मोड में सिंक वैसे ही काम करता है, बस कुछ ज़्यादा '
      'अनुरोधों के साथ।';
  @override
  String get syncTestInvalidUrl => 'मान्य पता नहीं';
  @override
  String get syncTestInvalidUrlHint =>
      'http:// या https:// पता डालें, उसमें उपयोगकर्ता या '
      'पासवर्ड न हो।';
  @override
  String get syncTestOffline => 'सर्वर तक पहुँच नहीं';
  @override
  String get syncTestOfflineHint =>
      'क्या VPN चालू है? 10.x या 192.168.x पता सिर्फ़ उसी '
      'नेटवर्क से काम करता है।';
  @override
  String get syncTestAuth => 'उपयोगकर्ता या पासवर्ड अस्वीकार';
  @override
  String get syncTestAuthHint => 'इन्हें जाँचें, फिर दोबारा टेस्ट करें।';
  @override
  String get syncTestNotFound => 'फ़ोल्डर मौजूद नहीं है';
  @override
  String get syncTestNotFoundHint => 'इसे सर्वर पर बनाएँ या पता ठीक करें।';
  @override
  String get syncTestUnsupported => 'यह WebDAV फ़ोल्डर नहीं है';
  @override
  String get syncTestUnsupportedHint =>
      'सर्वर जवाब देता है, पर WebDAV की तरह नहीं।';
  @override
  String get syncTestFailed => 'जाँच सफल नहीं हुई';
  @override
  String get syncNowAction => 'अभी सिंक करें';
  @override
  String get syncSectionServer => 'सर्वर';
  @override
  String get syncServerRow => 'पता, उपयोगकर्ता और पासवर्ड';
  @override
  String get syncRetestTitle => 'सर्वर को फिर से जाँचें';
  @override
  String syncProbedAgo(String when) => 'पिछली जाँच: $when';
  @override
  String get syncDisconnectTitle => 'इस लाइब्रेरी को डिस्कनेक्ट करें';
  @override
  String get syncDisconnectSubtitle => 'फ़ाइलें यहाँ और सर्वर पर बनी रहती हैं';
  @override
  String get syncDisconnectConfirmTitle => 'सिंक डिस्कनेक्ट करें?';
  @override
  String get syncDisconnectConfirmBody =>
      'यह लाइब्रेरी इस डिवाइस पर सिंक होना बंद कर देती है। कोई '
      'फ़ाइल नहीं हटती, न यहाँ न सर्वर पर। अगर आप इसे फिर से '
      'जोड़ते हैं, तो पहला सिंक शुरू से होगा।';
  @override
  String get syncDisconnectConfirm => 'डिस्कनेक्ट करें';
  @override
  String get syncFirstTitle => 'पहला सिंक';
  @override
  String get syncFirstIntro =>
      'मैंने लाइब्रेरी की तुलना सर्वर के फ़ोल्डर से की:';
  @override
  String get syncFirstUpload => 'अपलोड करनी हैं';
  @override
  String get syncFirstDownload => 'डाउनलोड करनी हैं';
  @override
  String get syncFirstBoth => 'दोनों तरफ़';
  @override
  String get syncFirstBothHint =>
      'एक जैसी: कोई ट्रांसफ़र नहीं। अलग: सुलझानी हैं';
  @override
  String get syncFirstNoDelete =>
      'पहला सिंक कुछ नहीं हटाता, न यहाँ न सर्वर पर।';
  @override
  String get syncStartAction => 'शुरू करें';
  @override
  String syncMassTrashTitle(int count) => '$count फ़ाइलें ट्रैश में भेजें?';
  @override
  String syncMassTrashBody(int count, int total) =>
      'सिंक की गई $total में से $count फ़ाइलें सर्वर पर नहीं '
      'हैं। आमतौर पर इसका मतलब होता है गलत पता, NAS की डिस्क '
      'माउंट न होना या गलती से खाली हुआ फ़ोल्डर।';
  @override
  String get syncMassTrashHint =>
      'अगर आपने इन्हें सच में किसी दूसरे डिवाइस पर हटाया है, तो '
      'पुष्टि करें: यहाँ ये ट्रैश में जाएँगी।';
  @override
  String get syncMassTrashConfirm => 'ट्रैश में भेजें';
  @override
  String syncMassDeleteTitle(int count) => 'सर्वर से $count फ़ाइलें हटाएँ?';
  @override
  String syncMassDeleteBody(int count, int total) =>
      'सिंक की गई $total में से $count फ़ाइलें यहाँ नहीं हैं। '
      'अगर आपने इन्हें नहीं हटाया, तो रद्द करें और लाइब्रेरी का '
      'फ़ोल्डर जाँचें।';
  @override
  String get syncMassDeleteConfirm => 'सर्वर से हटाएँ';
  @override
  String get syncTooltip => 'सिंक करें';
  @override
  String get syncStageConnecting => 'सर्वर से जुड़ रहा है…';
  @override
  String get syncStageComparing => 'सर्वर से तुलना हो रही है…';
  @override
  String syncStageApplying(int done, int total) =>
      'सिंक हो रहा है · $total में से $done';
  @override
  String get syncStatusWarnings => 'चेतावनियों के साथ सिंक हुआ';
  @override
  String syncConflictsHeader(int count) => 'यहाँ और सर्वर पर बदली गईं · $count';
  @override
  String get syncConflictHint => 'किसी भी संस्करण को छुआ नहीं गया';
  @override
  String get syncResolveAction => 'सुलझाएँ';
  @override
  String syncFailuresHeader(int count) => 'सिंक नहीं हुईं · $count';
  @override
  String get syncFailuresHint => 'अगले सिंक में फिर कोशिश होगी';
  @override
  String get syncAbortAuth => 'सर्वर ने पासवर्ड अस्वीकार किया';
  @override
  String get syncAbortMissingPassword => 'कोई पासवर्ड सहेजा नहीं गया';
  @override
  String get syncAbortOffline => 'सर्वर तक पहुँच नहीं';
  @override
  String get syncAbortRemoteMissing => 'सर्वर पर फ़ोल्डर अब नहीं है';
  @override
  String get syncAbortUnsupported => 'सर्वर अब WebDAV की तरह काम नहीं करता';
  @override
  String get syncAbortFailed => 'सिंक सफल नहीं हुआ';
  @override
  String get syncAbortNotConfirmed => 'सिंक रद्द किया गया';
  @override
  String get syncAbortNothingTouched =>
      'किसी फ़ाइल को छुआ नहीं गया। आपके बदलाव अगले सफल सिंक तक '
      'यहीं रहेंगे।';
  @override
  String syncLastSuccess(String when) => 'पिछला सफल सिंक: $when';
  @override
  String get syncNoSuccessYet => 'अभी तक कोई सफल सिंक नहीं';
  @override
  String get syncUpdatePasswordAction => 'पासवर्ड अपडेट करें';
  @override
  String get syncRetryAction => 'फिर कोशिश करें';
  @override
  String get syncOpenSettingsAction => 'सेटिंग';
  @override
  String get syncCloseAction => 'बंद करें';
  @override
  String get syncDoneSnack => 'सिंक पूरा हुआ';
  @override
  String syncTrashedSnack(int count) => count == 1
      ? 'सिंक पूरा हुआ · कहीं और हटाई गई 1 फ़ाइल ट्रैश में है'
      : 'सिंक पूरा हुआ · कहीं और हटाई गई $count फ़ाइलें ट्रैश में '
            'हैं';
  @override
  String syncConflictsSnack(int count) => count == 1
      ? 'सिंक पूरा हुआ · सुलझाने के लिए 1 टकराव'
      : 'सिंक पूरा हुआ · सुलझाने के लिए $count टकराव';
  @override
  String get syncShowAction => 'दिखाएँ';
  @override
  String get syncConflictTitle => 'टकराव सुलझाएँ';
  @override
  String get syncConflictLegend =>
      '− वाली पंक्तियाँ सर्वर की हैं, + वाली पंक्तियाँ इस डिवाइस '
      'की।';
  @override
  String get syncConflictBinary =>
      'यह टेक्स्ट फ़ाइल नहीं है: चुनें कि कौन-सी कॉपी रखनी है।';
  @override
  String get syncConflictKeepNote =>
      'जो कॉपी आप नहीं रखते, वह नोट के इतिहास में रहती है।';
  @override
  String get syncKeepLocal => 'इस डिवाइस वाली रखें';
  @override
  String get syncKeepRemote => 'सर्वर वाली रखें';
  @override
  String get syncConflictIdentical => 'दोनों संस्करण एक जैसे हैं';
  @override
  String get syncConflictLoadFailed => 'दोनों संस्करण नहीं पढ़े जा सके';
  @override
  String get syncResolveFailed => 'टकराव नहीं सुलझाया जा सका';
  @override
  String get syncResolved => 'टकराव सुलझ गया';
  @override
  String get syncSectionWhen => 'कब सिंक करें';
  @override
  String get syncAutoTitle => 'अपने-आप';
  @override
  String get syncAutoSubtitle => 'बदलावों के बाद, खोलने पर और तय अंतराल पर';
  @override
  String get syncIntervalTitle => 'सर्वर जाँचने का अंतराल';
  @override
  String get syncIntervalSubtitle => 'सिर्फ़ ऐप खुला रहने पर';
  @override
  String get syncIntervalDialogBody =>
      'ऐप खुला रहते हुए दूसरे डिवाइस पर किए गए बदलाव देखने के लिए। '
      '«कभी नहीं» चुनने पर सिर्फ़ बदलावों के बाद और खोलने पर।';
  @override
  String syncIntervalMinutes(int count) =>
      count == 1 ? '1 मिनट' : '$count मिनट';
  @override
  String get syncIntervalNever => 'कभी नहीं';
  @override
  String get syncWifiOnlyTitle => 'सिर्फ़ Wi-Fi पर';
  @override
  String get syncWifiOnlySubtitle => 'मोबाइल डेटा पर सिर्फ़ हाथ से सिंक करें';
  @override
  String syncPendingChanges(int count) =>
      count == 1 ? '1 बदलाव बाकी है' : '$count बदलाव बाकी हैं';
  @override
  String syncRetryIn(String wait) => '$wait में फिर कोशिश होगी';
  @override
  String syncWaitSeconds(int seconds) => '$seconds सेकंड';
  @override
  String syncWaitMinutes(int minutes) => '$minutes मिनट';
  @override
  String get syncWaitingForWifi => 'Wi-Fi का इंतज़ार';
  @override
  String get syncWaitingForNetwork => 'कनेक्शन का इंतज़ार';
  @override
  String get syncMobileDataHint =>
      '«अभी सिंक करें» फिर भी मोबाइल डेटा इस्तेमाल करता है।';
  @override
  String get syncQueueKeptHint =>
      'बदलाव यहीं रहते हैं, ऐप बंद करने पर भी, और सर्वर के जवाब देते ही '
      'अपने-आप भेज दिए जाते हैं।';
  @override
  String get syncAutoPaused => 'अपने-आप सिंक रुका हुआ है';
  @override
  String get syncPausedAuthHint =>
      'पासवर्ड अपडेट करने या हाथ से सिंक करने पर यह फिर शुरू होगा।';
  @override
  String get syncPausedServerHint =>
      'पता ठीक करने या हाथ से सिंक करने पर यह फिर शुरू होगा।';
  @override
  String get syncPausedConfirmHint =>
      '«अभी सिंक करें» दिखाता है कि क्या हटेगा, और पहले पूछता है।';
  @override
  String get syncNeedsConfirmation => 'आपकी पुष्टि का इंतज़ार';
  @override
  String get syncMergeIntro =>
      'जो बदलाव ओवरलैप नहीं होते वे पहले ही मिला दिए गए हैं; '
      'जहाँ होते हैं वहाँ चुनें कि क्या रखना है।';
  @override
  String get syncMergeClean =>
      'दोनों संस्करण अपने-आप मिल जाते हैं: कुछ भी ओवरलैप नहीं होता।';
  @override
  String get syncMergeNoBase =>
      'मिलाने के लिए कोई साझा संस्करण नहीं है, इसलिए पूरी फ़ाइल '
      'चुननी होगी।';
  @override
  String syncMergeOverlap(int index, int total) => 'ओवरलैप $index / $total';
  @override
  String get syncMergeFromLocal => 'इस डिवाइस से';
  @override
  String get syncMergeFromRemote => 'सर्वर से';
  @override
  String get syncMergeRemovedLines => 'हटाई गई पंक्तियाँ';
  @override
  String get syncMergeKeepLocal => 'मेरी';
  @override
  String get syncMergeKeepRemote => 'सर्वर की';
  @override
  String get syncMergeKeepBoth => 'दोनों';
  @override
  String get syncMergeSave => 'मिलान सहेजें';
  @override
  String get syncMergeKeepWhole => 'या पूरी एक कॉपी रखें';
}
