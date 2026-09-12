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
  String get debugLogsTitle => 'डिबग लॉग';
  @override
  String get debugLogsSubtitle => 'ऐप के घटनाक्रम को मेमोरी बफ़र में दर्ज रखें';
  @override
  String get lineNumbersTitle => 'पंक्ति संख्याएँ';
  @override
  String get lineNumbersSubtitle => 'नोट एडिटर में पंक्ति-संख्या स्तंभ दिखाएँ';
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
  String get settingsPreviewEnabledTitle => 'पूर्वावलोकन';
  @override
  String get settingsPreviewEnabledSubtitle =>
      'स्रोत एडिटर के बगल में रेंडर किया गया नोट दिखाएँ';
  @override
  String get switchToWysiwygTooltip => 'WYSIWYG एडिटर पर जाएँ';
  @override
  String get switchToSourceTooltip => 'Markdown स्रोत पर जाएँ';
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
  String indentWidthValue(int spaces) => '$spaces spaces';

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

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'क्विक नोट';
  @override
  String get shortcutNewTodo => 'नया टू-डू';
  @override
  String get shortcutNewNote => 'नया नोट';
  @override
  String get shortcutNewList => 'नई सूची';
  @override
  String get shortcutToggleSidebar => 'फ़ाइल ट्री दिखाएँ/छिपाएँ';
  @override
  String get shortcutEditorSection => 'एडिटर में';
  @override
  String get shortcutFind => 'ढूँढें';
  @override
  String get shortcutReplace => 'ढूँढें और बदलें';
  @override
  String get shortcutSavingNote =>
      'बदलाव अपने-आप सहेजे जाते हैं: सहेजने का कोई शॉर्टकट नहीं है।';

  // Editor status bar.
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
  String get newFolderTitle => 'नया फ़ोल्डर';
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
}
