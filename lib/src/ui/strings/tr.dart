// The Turkish strings.
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class TurkishStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];
  @override
  List<String> get monthNamesShort => const [
    'Oca',
    'Şub',
    'Mar',
    'Nis',
    'May',
    'Haz',
    'Tem',
    'Ağu',
    'Eyl',
    'Eki',
    'Kas',
    'Ara',
  ];
  @override
  List<String> get weekdayNames => const [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];
  @override
  List<String> get weekdayNamesShort => const [
    'Paz',
    'Sal',
    'Çar',
    'Per',
    'Cum',
    'Cmt',
    'Pzr',
  ];

  // Settings: editor toggles.
  @override
  String get trashTitle => 'Çöp kutusu';
  @override
  String get trashSubtitle =>
      'Silinen öğeler .trash/ klasörüne gider (kapalı = kalıcı silme)';
  @override
  String get trashAutoEmptyTitle => 'Çöp kutusunu otomatik boşalt';
  @override
  String get trashAutoEmptySubtitle =>
      'Kütüphane açıldığında daha eski silmeler kalıcı olarak gider';
  @override
  String trashAutoEmptyValue(int days) =>
      days == 0 ? 'Hiçbir zaman' : '$days gün';
  @override
  String get debugLogsTitle => 'Hata ayıklama kayıtları';
  @override
  String get debugLogsSubtitle => 'Uygulama olaylarını bellek tamponuna yazar';
  @override
  String get lineNumbersTitle => 'Satır numaraları';
  @override
  String get lineNumbersSubtitle =>
      'Düzenleyicide satır numarası sütununu gösterir';
  @override
  String get readableLineLengthTitle => 'Okunabilir satır uzunluğu';
  @override
  String get readableLineLengthSubtitle =>
      'Notun metnini pencerenin tüm genişliği yerine ortalanmış bir sütunda '
      'tut';
  @override
  String get noteColumnWidthTitle => 'Sütun genişliği';
  @override
  String get noteColumnWidthSubtitle =>
      'Not sütununun genişliği, piksel cinsinden';
  @override
  String noteColumnWidthValue(int pixels) => '$pixels px';
  @override
  String get keyboardOnOpenTitle => 'Açılışta klavye';
  @override
  String get keyboardOnOpenSubtitle =>
      'Not açılır açılmaz klavyeyi gösterir (kapalı = ilk dokunuşta)';
  @override
  String get editorKindSource => 'Markdown kaynağı';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get editorKindSourceSubtitle => 'Yazıldığı gibi Markdown kaynağı';
  @override
  String get editorKindWysiwygSubtitle =>
      'Biçimlendirilmiş metin, yerinde düzenlenir';
  @override
  String get settingsFolderToCreate => 'oluşturulacak';
  @override
  String get settingsSearchHint => 'Ayarlarda ara';
  @override
  String settingsSearchResults(int count) =>
      count == 1 ? '1 ayar bulundu' : '$count ayar bulundu';
  @override
  String get settingsToggleOn => 'Açık';
  @override
  String get settingsToggleOff => 'Kapalı';
  @override
  String get settingsPreviewEnabledTitle => 'Önizleme';
  @override
  String get settingsPreviewEnabledSubtitle =>
      'Biçimlendirilmiş notu kaynak düzenleyicinin yanında gösterir';
  @override
  String get switchToWysiwygTooltip => 'WYSIWYG düzenleyicisine geç';
  @override
  String get switchToSourceTooltip => 'Markdown kaynağına geç';
  @override
  String get switchToSourceLabel => 'Kaynak';
  @override
  String get switchToWysiwygLabel => 'WYSIWYG';
  @override
  String get wysiwygTooLarge =>
      'Bu not WYSIWYG düzenleyicisi için çok büyük. Markdown kaynağında '
      'açın.';

  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'Görünüm';
  @override
  String get settingsSectionEditor => 'Düzenleyici';
  @override
  String get settingsSectionLibrary => 'Kütüphane';
  @override
  String get settingsSectionReminders => 'Hatırlatıcılar';
  @override
  String get settingsSectionShortcuts => 'Klavye';
  @override
  String get keyboardShortcutsTitle => 'Klavye kısayolu';

  // Settings home (issue #104): the groups the areas sit under.
  @override
  String get settingsGroupApp => 'App';
  @override
  String settingsGroupLibrary(String name) => 'Kütüphane $name';
  @override
  String get settingsGroupLibraryHint => 'yalnızca bu kütüphaneye uygulanır';
  @override
  String get settingsGroupMaintenance => 'Bakım';

  // Settings home rows.
  @override
  String get settingsAreaFolders => 'Klasörler ve yollar';
  @override
  String get settingsAreaTrashHistory => 'Çöp kutusu ve kronoloji';
  @override
  String get settingsAreaDiagnostics => 'Teşhis ve bilgi';
  @override
  String get settingsAreaKeyboardDisabled =>
      'Bağlı fiziksel bir klavye gerekli';
  @override
  String get settingsSectionUpdates => 'Güncellemeler';
  @override
  String get autoUpdateTitle => 'Otomatik güncellemeler';
  @override
  String get autoUpdateSubtitle =>
      "GitHub Releases'ı açılışta ve 6 saatte bir kontrol et";
  @override
  String get checkForUpdatesTitle => 'Güncellemeleri kontrol et';
  @override
  String updateAvailableMessage(Object version) => 'Niman $version mevcut';
  @override
  String get updateUpToDate => 'Niman güncel';
  @override
  String get updateCheckFailed => 'Güncelleme kontrolü başarısız';
  @override
  String updateSavedTo(Object path) => 'Güncelleme şuraya kaydedildi: $path';
  @override
  String get updateInstallerStarted => 'Yükleyici başlatıldı';
  @override
  String get settingsSectionDiagnostics => 'Teşhis';
  @override
  String get settingsSpellCheckTitle => 'Yazım denetimi';
  @override
  String get settingsSpellCheckSubtitle =>
      'Yazarken yanlış yazılan kelimeleri altını çizer.';
  @override
  String get spellCheckDictionaryTitle => 'Sözlük';
  @override
  String get spellCheckDictionarySystem => 'Sistem varsayılanı';
  @override
  String get spellCheckDictionaryChoiceTitle => 'Sözlükleri seçin';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      'Bu kütüphanenin yazıldığı her dili seçin. Kelime seçili sözlüklerden '
      'biri tarafından tanındığında geçer; seçim yoksa sistem karar '
      'verir.';
  @override
  String get spellCheckNoDictionaries => 'Bu sistemde sözlük bulunamadı.';

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => 'Yazım denetimi';
  @override
  String get spellCheckTitle => 'Yazım';
  @override
  String get spellCheckEmpty => 'Yazım hatası yok.';
  @override
  String get spellCheckUnavailable => 'hunspell bu sistemde kurulu değil.';
  @override
  String get spellCheckNoSuggestions => 'Öneri yok';
  @override
  String spellCheckCount(int count) => '$count incelemeye';
  @override
  String spellCheckLine(int line) => '$line. satır';
  @override
  String get addWordToDictionary => 'Sözlüğe ekle';

  @override
  String indentWidthValue(int spaces) => '$spaces boşluk';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => 'Parlaklık';
  @override
  String get themeBrightnessSubtitle => 'Açık, koyu veya cihazın ayarına göre';
  @override
  String get themeBrightnessSystem => 'Sistem';
  @override
  String get themeBrightnessDay => 'Açık';
  @override
  String get themeBrightnessNight => 'Koyu';
  @override
  String get themePaletteTitle => 'Renk paleti';
  @override
  String get themePaletteSubtitle => 'Arayüz ve not renkleri';
  @override
  String get themePaletteSystem => 'Sistem';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'Arayüz yazı boyutu';
  @override
  String get uiTextScaleSubtitle =>
      'Ağaç, kartlar ve diyaloglar. Sistem ayarının üstüne';
  @override
  String get noteTextScaleTitle => 'Not yazı boyutu';
  @override
  String get noteTextScaleSubtitle =>
      'Düzenleyici ve önizleme, her zaman senkronize';

  // Settings: preview mode.
  @override
  String get previewModeTitle => 'Önizleme modu';
  @override
  String get previewModeSubtitle =>
      'Önizleme, ekranı düzenleyiciyle paylaşır mı yoksa onun yerini '
      'alır mı';
  @override
  String get previewModeAuto => 'Yan yana';
  @override
  String get previewModeSwitch => 'Tam ekran';
  @override
  String get splitRatioTitle => 'Bölme oranı';
  @override
  String get splitRatioSubtitle => 'Önizleme yanındayken düzenleyicinin payı';

  // Settings: editor formatting.
  @override
  String get linkTypeTitle => 'Bağlantı biçimi';
  @override
  String get linkTypeSubtitle =>
      'Düzenleyicide bağlantı düğmesi neyi yapıştırır';
  @override
  String get linkTypeWikilink => 'Wikilink';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get missingNoteLocationTitle => 'Eksik notları oluştur';
  @override
  String get missingNoteLocationRoot => 'Kütüphane kökünde';
  @override
  String get missingNoteLocationCurrentFolder => 'Mevcut klasörde';
  @override
  String get indentWidthTitle => 'Girinti genişliği';
  @override
  String get indentWidthSubtitle =>
      'Düzenleyicide her girinti düzeyi için eklenen boşluklar';

  // Settings: language (T-L10N-04).
  @override
  String get languageTitle => 'Dil';
  @override
  String get languageSubtitle => 'Uygulamanın kendisinin yazı dili';
  @override
  String get languageSystem => 'Sistem';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Öğe ekle';
  @override
  String get listAddTooltip => 'Öğe ekle';
  @override
  String get listEmpty => 'Henüz öğe yok';
  @override
  String get listDragHandleLabel => 'Öğeyi yeniden sırala';

  // Audio note kind (issue #56).
  @override
  String get audioEmpty => 'Henüz kayıt yok';
  @override
  String get audioRecord => 'Kayda başla';
  @override
  String get audioStop => 'Durdur';
  @override
  String get audioPlay => 'Oynat';
  @override
  String get audioDelete => 'Kaydı sil';
  @override
  String get audioImport => 'Ses dosyası içe aktar';
  @override
  String get audioRecording => 'Kaydediliyor…';
  @override
  String get audioPermissionDenied =>
      'Mikrofon izni reddedildi — kayıt için gerekli.';
  @override
  String get newAudioNoteTitle => 'Yeni sesli not';
  @override
  String get newAudioNoteDefault => 'Kaydım';
  @override
  String get showAudioTooltip => 'Kayıtları göster';
  @override
  String get audioMessageHint => 'Bir not yaz…';
  @override
  String get audioSend => 'Gönder';
  @override
  String get audioRename => 'Kaydı yeniden adlandır';
  @override
  String get audioDescriptionHint => 'Bu kaydı açıkla…';
  @override
  String get audioEditDescription => 'Açıklamayı düzenle';
  @override
  String get audioDeleteNote => 'Notu sil';
  @override
  String get audioEditNote => 'Notu düzenle';
  @override
  String get audioPause => 'Duraklat';
  @override
  String get audioEditTitle => 'Başlığı düzenle';
  @override
  String get audioTitleHint => 'Bu kayda bir başlık ver…';
  @override
  String audioUntitled(int n) => 'Kayıt $n';
  @override
  String get audioMoreActions => 'Diğer işlemler';
  @override
  String get audioDiscardRecording => 'Kaydı at';
  @override
  String get audioPauseRecording => 'Kaydı duraklat';
  @override
  String get audioResumeRecording => 'Kayda devam et';
  @override
  String get audioRecordingPaused => 'Duraklatıldı';
  @override
  String get audioSavingRecording => 'Kaydediliyor…';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Hızlı not';
  @override
  String get shortcutNewTodo => 'Yeni görev';
  @override
  String get shortcutNewNote => 'Yeni not';
  @override
  String get shortcutNewList => 'Yeni liste';
  @override
  String get shortcutNewAudio => 'Yeni sesli not';
  @override
  String get shortcutToggleSidebar => 'Dosya ağacını göster veya gizle';
  @override
  String get shortcutCloseTab => 'Geçerli notu kapat';
  @override
  String get shortcutNextTab => 'Sonraki açık not';
  @override
  String get shortcutPreviousTab => 'Önceki açık not';
  @override
  String get shortcutEditorSection => 'Düzenleyicide';
  @override
  String get shortcutFind => 'Bul';
  @override
  String get shortcutReplace => 'Bul ve değiştir';
  @override
  String get shortcutSavingNote =>
      'Değişiklikler otomatik kaydedilir, bu yüzden bir kaydetme '
      'kısayolu yoktur.';

  // Editor status bar.
  @override
  String get noteStatusLoading => 'Yükleniyor…';
  @override
  String get noteStatusSaving => 'Kaydediliyor…';
  @override
  String get noteStatusUnsaved => 'Kaydedilmedi';
  @override
  String get noteStatusSaved => 'Kaydedildi';
  @override
  String get noteStatusError => 'Hata';
  @override
  String get noteNotText =>
      'Bu dosya bir metin notu değil, bu yüzden Niman onu burada gösteremiyor.';
  @override
  String get noteLoadFailed => 'Bu not açılamadı.';
  @override
  String wordCount(int count) => '$count kelime';
  @override
  String get outlineTooltip => 'İçerik';
  @override
  String get outlineNoHeadings => 'Başlık yok';
  @override
  String get outlineNoTitle => '(başlıksız)';

  // Editor toolbar: one name per button, used as its tooltip in the
  // editor and as its row title in the toolbar settings.
  @override
  String get toolbarBold => 'Kalın';
  @override
  String get toolbarItalic => 'İtalik';
  @override
  String get toolbarStrikethrough => 'Üstü çizili';
  @override
  String get toolbarSuperscript => 'Üst simge';
  @override
  String get toolbarUnderline => 'Altı çizili';
  @override
  String get toolbarLink => 'Bağlantı';
  @override
  String get toolbarCode => 'Kod bloğu';
  @override
  String get toolbarImage => 'Görsel ekle';
  @override
  String get toolbarHeading => 'Başlık';
  @override
  String get toolbarList => 'Liste';
  @override
  String get toolbarOrderedList => 'Numaralı liste';
  @override
  String get toolbarQuote => 'Alıntı';
  @override
  String get toolbarIndent => 'Girintile';
  @override
  String get toolbarOutdent => 'Girintiyi azalt';

  // Editor tools (#136): the Tools button, the sheet it opens, and
  // the list count that is the first tool in it.
  @override
  String get toolbarTools => 'Araçlar';
  @override
  String get editorToolsTitle => 'Düzenleyici araçları';
  @override
  String get toolCountListTitle => 'Listeyi say';
  @override
  String get toolCountListSubtitle =>
      'Satırların saydığı şeyleri toplar, onay listesi olarak';
  @override
  String get toolCountListNeedsList => 'Bu notta sayılacak liste yok';
  @override
  String get tallySourceLabel => 'Liste';
  @override
  String get tallyCutLabel => 'Her satırı şöyle oku';
  @override
  String get tallyCutDash => 'Ad - değerler';
  @override
  String get tallyCutColon => 'Ad: değerler';
  @override
  String get tallyCutCommas => 'Virgülle ayrılmış değerler';
  @override
  String get tallyCutWhole => 'Satırın tamamı, tek değer olarak';
  @override
  String get tallySortLabel => 'Sıralama';
  @override
  String get tallySortCount => 'Önce en çok olanlar';
  @override
  String get tallySortAlphabetical => 'Alfabetik';
  @override
  String get tallySortFirstSeen => 'Listedeki sırayla';
  @override
  String get tallyInsert => 'Ekle';
  @override
  String get tallyUpdate => 'Güncelle';
  @override
  String get tallyNothingToCount => 'Burada sayılacak bir şey yok';
  @override
  String get headingDialogTitle => 'Başlık düzeyi';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => 'Düzenleyici araç çubuğu';
  @override
  String get toolbarSettingsHint =>
      'Yeniden sıralamak için sürükleyin. Göz, düğmeyi gösterir veya '
      'gizler.';
  @override
  String get toolbarShowButton => 'Göster';
  @override
  String get toolbarHideButton => 'Gizle';
  @override
  String get toolbarResetOrder => 'Varsayılanlara dön';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => 'Önizlemeyi göster';
  @override
  String get showEditorTooltip => 'Düzenleyiciyi göster';
  @override
  String get enterFullScreenTooltip => 'Tam ekran';
  @override
  String get exitFullScreenTooltip => 'Tam ekrandan çık';

  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '(çözümlenmemiş HTML tablo)';

  // Search (T-M3-05).
  @override
  String get searchHint => 'Notlarda ara';
  @override
  String get searchModeWords => 'Kelime';
  @override
  String get searchModeContains => 'İçeriyor';
  @override
  String get searchEmptyHint =>
      'Kütüphanede aramak için yazın veya frontmatter filtresi için '
      'key = value';
  @override
  String get searchTooShortHint => 'En az 2 karakter yazın';
  @override
  String get searchNoMatches => 'Eşleşme yok';
  @override
  String get searchLoadMore => 'Daha fazla göster';

  // Replace (T-M3-10): the search screen's optional exact-word replace.
  @override
  String get replaceTooltip => 'Değiştir…';
  @override
  String get replaceInNoteAction => 'Bu notta değiştir…';
  @override
  String get replaceInThisNote => 'Bu notta değiştir';
  @override
  String get replaceWithLabel => 'Buna değiştir';
  @override
  String get replaceCaseSensitive => 'Büyük/küçük harf duyarlı';
  @override
  String get replaceWholeWordsHint => 'yalnızca tam kelimeler değiştirilir';
  @override
  String get replaceConfirm => 'Değiştir';
  @override
  String get replaceCancel => 'Kapat';
  @override
  String get replaceUnavailable => 'Değiştirme şu an kullanılamıyor';

  // Editor find & replace (the classic in-note bar, re_editor's find
  // controller + NimanFindPanel).
  @override
  String get findInNoteTooltip => 'Notta bul';
  @override
  String get editorFindHint => 'Bul';
  @override
  String get editorReplaceHint => 'Değiştir';
  @override
  String get editorFindCaseTooltip => 'Büyük/küçük harf eşleşmesi';
  @override
  String get editorFindPreviousTooltip => 'Önceki eşleşme';
  @override
  String get editorFindNextTooltip => 'Sonraki eşleşme';
  @override
  String get editorFindCloseTooltip => 'Aramayı kapat';
  @override
  String get editorFindReplaceModeTooltip => 'Değiştirme modu';
  @override
  String get editorReplaceOneTooltip => 'Bu eşleşmeyi değiştir';
  @override
  String get editorReplaceAllTooltip => 'Tümünü değiştir';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => 'Etiketler';
  @override
  String get tagsTitle => 'Etiketler';
  @override
  String get tagsEmpty =>
      "Henüz etiket yok — #etiket veya frontmatter'a tags ekleyin";
  @override
  String get tagsBackTooltip => 'Aramaya dön';
  @override
  String get tagsNotesEmpty => 'Bu etikete sahip not yok';
  @override
  String tagsNotesCapped(int limit) =>
      'Sadece ilk $limit gösteriliyor — daraltmak için etiketi arayın';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => 'Bağlantı bulunamadı';
  @override
  String get headingNotFoundTitle => 'Başlık bulunamadı';
  @override
  String get ambiguousLinkTitle => 'Birden çok not eşleşiyor';
  @override
  String get openLinkFailed => 'Bağlantı açılamadı';

  // Dead-link note creation (issue #78).
  @override
  String get missingNoteDialogTitle => 'Not mevcut değil';
  @override
  String missingNoteDialogBody(String path) => '"$path" oluşturulsun mu?';
  @override
  String missingNoteFolderMissing(String folder) =>
      '"$folder" klasörü mevcut değil';

  // Task lists (T-TD-04).
  @override
  String get todoOpen => 'Açık';
  @override
  String get todoDone => 'Biten';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => 'Tüm tarihler';
  @override
  String get todoFilter => 'Filtreler';
  @override
  String get todoNoTokens => 'Bu listede token yok';
  @override
  String get todoCountOpen => 'açık';
  @override
  String get todoCountDone => 'biten';
  @override
  String get todoEmptyOpen => 'Henüz açık görev yok';
  @override
  String get todoEmptyDone => 'Henüz biten yok';
  @override
  String get todoEmptyFiltered => 'Eşleşen görev yok';
  @override
  String get todoTitle => 'Görevler';
  @override
  String get todoAddTooltip => 'Görev ekle';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'todo.txt biçimi';
  @override
  String get todoHelpTooltip => 'Biçim yardımı';
  @override
  String get todoHelpIntro =>
      'Görevleriniz düz bir metin dosyasıdır, satır başına bir görev. '
      'Niman sözdizimini sizin için yazar ama hiçbir şeyi gizlemez: '
      'dosyayı herhangi bir düzenleyicide düzenleyebilir, Niman geri '
      'okur.';
  @override
  String get todoHelpFilesTitle => 'İki dosya';
  @override
  String get todoHelpFilesBody =>
      'Açık görevler kütüphanenin kökündeki todo.txt dosyasındadır. '
      'Bitirince satır done.txt dosyasına taşınır, böylece todo.txt '
      'kısa kalır. Bitmiş bir satır todo.txt dosyasında tekrar '
      'görünürse Niman dosyaları okuduğunda arşivler.';
  @override
  String get todoHelpLineTitle => 'Satır yapısı';
  @override
  String get todoHelpLineBody =>
      'Açıklamadan önce her şey isteğe bağlıdır ve bu sırada gelir:';
  @override
  String get todoHelpDoneBody =>
      'Görevi bitmiş olarak işaretler. Kutuyu işaretlediğinizde Niman '
      'bunu ekler.';
  @override
  String get todoHelpPriority => '(A) ila (Z)';
  @override
  String get todoHelpPriorityBody =>
      'Öncelik. A en yüksektir. Listedey rozet olarak görünür.';
  @override
  String get todoHelpDatesBody =>
      'Bitiş tarihi, ardından oluşturma tarihi. Tek tarih varsa, satır '
      'x ile başlamadıkça o oluşturma tarihidir.';
  @override
  String get todoHelpTokensTitle => 'Projeler, bağlamlar ve etiketler';
  @override
  String get todoHelpTokensBody =>
      'Açıklamada herhangi bir yerde, bu ön eklerden biriyle yazılan '
      'bir kelime, filtrelenebilen bir çipe dönüşür. Hiçbiri yerleşik '
      'değildir: token ancak yazdığınızda vardır.';
  @override
  String get todoHelpProjectBody => 'Görevin ne olduğu, örn. +inşa veya +tez.';
  @override
  String get todoHelpContextBody =>
      'Nerede veya nasıl yapacağınız, örn. @ev veya @telefon';
  @override
  String get todoHelpHashtagBody =>
      'Serbest etiket, kalan ikisinin kapsamadığı her şey için';
  @override
  String get todoHelpTagsTitle => 'Tarihler ve hatırlatıcılar';
  @override
  String get todoHelpTagsBody =>
      'Bunlar key:value etiketleridir. Niman görev diyaloğundan yazar '
      've satırda nerede görünseler okur.';
  @override
  String get todoHelpDueBody =>
      'Bitiş tarihi. Rozetin rengini ve tarih filtresini belirler.';
  @override
  String get todoHelpRemBody =>
      'Bildirim ne zaman gönderilir, yerel saatinize göre. Ekran '
      'kapalıyken ve uygulama kapalıyken bile çalışır.';
  @override
  String get todoHelpRemDesktop =>
      "Masaüstünde Niman'ın saat geldiğinde çalışıyor olması gerekir: "
      'hatırlatıcı uygulama açıkken görünür, kapalıysa hiçbir şey '
      'çalışmaz.';
  @override
  String get todoHelpOtherBody =>
      'Tamamen yazıldıkları gibi saklanır, böylece başka todo.txt '
      'uygulamalarından etiketler taşıma boyunca yaşar. Niman bunları '
      'çalıştırmaz. rec: included: tekrarlayan görev henüz tekrarlanmaz.';
  @override
  String get todoHelpEditTitle => 'Niman dışında düzenleme';
  @override
  String get todoHelpEditBody =>
      'Dokunmadığınız görev byte-byte geri döner, tuhaf boşluklar '
      'dahil. Bir satırı düzenlerseniz Niman yalnızca o satırı kendi '
      'biçiminde yeniden yazar, dosyanın geri kalanına dokunmaz.';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => 'Görev ekle';
  @override
  String get todoEditTitle => 'Görevi düzenle';
  @override
  String get todoDescriptionHint => 'Açıklama';
  @override
  String get todoCancel => 'İptal';
  @override
  String get todoSave => 'Kaydet';
  @override
  String get todoEditAction => 'Düzenle';
  @override
  String get todoDeleteAction => 'Sil';

  // Task filters (T-TD-05).
  @override
  String get todoDueOverdue => 'Geciken';
  @override
  String get todoDueToday => 'Bugün';
  @override
  String get todoDueNext7 => 'İlk 7 gün';
  @override
  String get todoDueNoDate => 'Tarih yok';
  @override
  String get todoRowDue => 'Bitişi';
  @override
  String get todoRowDueToday => 'Bugün bitiyor';
  @override
  String get todoSortTooltip => 'Sırala';
  @override
  String get todoSortDue => 'Bitiş tarihi';
  @override
  String get todoSortPriority => 'Öncelik';
  @override
  String get todoSortCreation => 'Oluşturma tarihi';

  // Task dialog pickers (T-TD-06).
  @override
  String get todoNoPriority => 'Öncelik yok';
  @override
  String get todoNoPriorityShort => 'Yok';
  @override
  String get todoMorePriorities => 'Daha fazla…';
  @override
  String get todoPriorityTitle => 'Öncelik';
  @override
  String get todoNoDueDate => 'Bitiş tarihi yok';
  @override
  String get todoNoReminder => 'Hatırlatıcı yok';
  @override
  String get todoAddProject => '+ Proje';
  @override
  String get todoAddContext => '@ Bağlam';
  @override
  String get todoAddHashtag => '# Etiket';

  // Task reminders (T-TD-07).
  @override
  String get todoReminderChannel => 'Görev hatırlatıcıları';
  @override
  String get todoReminderChannelDescription =>
      'Hatırlatıcı saati olan görevler için planlanmış alarm.';
  @override
  String get todoReminderBody => 'Görev hatırlatıcısı';
  @override
  String get todoReminderFallbackTitle => 'Görev hatırlatıcısı';
  @override
  String get todoReminderBlocked =>
      'Bildirimler kapalı, bu yüzden hatırlatıcılar görünmeyecek.';
  @override
  String get todoReminderBattery =>
      'Niman için pil optimizasyonu etkin. Sistem uygulamayı uyku '
      'durumuna alabilir ve beklenen hatırlatıcıları kaçıra bilir.';
  @override
  String get todoReminderInexact =>
      'Bu cihaz kesin alarmlara izin vermez, bu yüzden hatırlatıcı '
      'ekran kapalıyken birkaç dakika geç gelebilir.';
  @override
  String get reminderShowTokensTitle => 'Hatırlatıcı bildirimlerinde etiketler';
  @override
  String get reminderShowTokensSubtitle =>
      '+proje, @bağlam ve #etiketi bildirim metninde tutar. Kapalıyken '
      'yalnızca atadığınız görevi gösterir.';
  @override
  String get todoReminderFixAction => 'Ayarları aç';
  @override
  String get todoReminderDismissAction => 'Kapat';
  @override
  String get todoReminderDue => 'Bitişi';

  // Actions and buttons shared by the dialogs (T-L10N-06).
  @override
  String get actionOk => 'Tamam';
  @override
  String get actionCancel => 'İptal';
  @override
  String get actionCreate => 'Oluştur';
  @override
  String get actionNew => 'Yeni';
  @override
  String get actionSave => 'Kaydet';
  @override
  String get actionClear => 'Temizle';
  @override
  String get actionChoose => 'Seç';
  @override
  String get actionDelete => 'Sil';
  @override
  String get actionRename => 'Yeniden adlandır';
  @override
  String get actionMove => 'Taşı';
  @override
  String get saveAndClose => 'Kaydet ve kapat';
  @override
  String get closeUnsavedTitle => 'Kaydedilmemiş değişiklikler';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return '“${names.first}” henüz kaydedilmemiş değişiklikler '
          'içeriyor. Kapatmadan önce kaydedilsin mi?';
    }
    return '${names.length} notta henüz kaydedilmemiş değişiklikler '
        'var. Kapatmadan önce kaydedilsin mi?';
  }

  @override
  String get closeSaveFailed => 'Kaydedilemedi; hâlâ açık.';
  @override
  String get actionRestore => 'Geri yükle';
  @override
  String get actionEmpty => 'Boşalt';

  // The shell: app bar, tabs and tree actions.
  @override
  String get hideSidebarTooltip => 'Kenar çubuğunu gizle (Ctrl+B)';
  @override
  String get showSidebarTooltip => 'Kenar çubuğunu göster (Ctrl+B)';
  @override
  String get windowMinimizeTooltip => 'Simge durumuna küçült';
  @override
  String get windowMaximizeTooltip => 'Büyüt';
  @override
  String get windowRestoreTooltip => 'Geri yükle';
  @override
  String get windowCloseTooltip => 'Kapat';
  @override
  String get tabFiles => 'Dosyalar';
  @override
  String get tabSearch => 'Ara';
  @override
  String get tabSettings => 'Ayarlar';
  @override
  String get quickNoteTitle => 'Hızlı not';
  @override
  String get treeEmpty => 'Henüz not yok';
  @override
  String get selectANote => 'Not seçin';
  @override
  String get showListTooltip => 'Listeyi göster';
  @override
  String get editRawTooltip => 'Ham olarak düzenle';
  @override
  String get sortAscTooltip => 'A-Z sırala';
  @override
  String get sortDescTooltip => 'Z-A sırala';
  @override
  String get newNoteTitle => 'Yeni not';
  @override
  String get newItemTooltip => 'Yeni';
  @override
  String get closeMenuTooltip => 'Kapat';
  @override
  String get newFolderTitle => 'Yeni klasör';
  @override
  String get newNoteSameFolder => 'Aynı klasörde yeni not';
  @override
  String get newFromTemplateSameFolder => 'Aynı klasörde şablondan yeni';
  @override
  String trashOriginalPath(String path) => 'buradaydı: $path';
  @override
  String get trashOriginalRoot =>
      'kitapl\u0131\u011f\u0131n k\u00f6k\u00fcndeydi';
  @override
  String trashItemCount(int count) =>
      count == 1 ? '1 \u00f6\u011fe' : '$count \u00f6\u011fe';
  @override
  String get newNoteHere => 'Buraya yeni not';
  @override
  String get newFolderHere => 'Buraya yeni klasör';
  @override
  String get newListNoteTitle => 'Yeni liste notu';
  @override
  String get newListNoteDefault => 'Listem';
  @override
  String get setAsQuickNote => 'Hızlı not olarak ayarla';
  @override
  String get currentQuickNote => 'Geçerli hızlı not';
  @override
  String get pinnedSection => 'Sabitlenmiş';
  @override
  String pinnedSectionCount(int count) => 'Sabitlenmiş · $count';
  @override
  String get templateFolderTitle => 'Şablon klasörü';
  @override
  String get newFromTemplateTitle => 'Şablondan yeni';
  @override
  String get newFromTemplateHere => 'Buradan şablondan yeni';
  @override
  String get templateFormTitle => 'Şablonu doldur';
  @override
  String get templateFormBacklink => 'Şuradan bağlantılı';
  @override
  String get templateFormNoNote => 'Not yok';
  @override
  String get templateFormPickNote => 'Not seç';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => 'Şablondaki yer tutucular';
  @override
  String get templateHelpSubtitle =>
      'Tarih, başlık ve doldurulacak diğer değerler';
  @override
  String get quickNoteSubtitle => 'Hızlı not sekmesinin açtığı not';
  @override
  String get listFolderSubtitle => 'Yeni görev listeleri';
  @override
  String get templateFolderSubtitle => 'Şablondan yeni kaynağı';
  @override
  String get attachmentsFolderSubtitle => 'Nota eklenen resimler ve ses';
  @override
  String get templateHelpIntro =>
      'Şablon, boşlukları olan düz bir nottur. Ondan not oluşturmak '
      'metnini kopyalar ve boşlukları doldurur.';
  @override
  String get templateHelpUnknown =>
      "Niman'ın tanımadığı bir yer tutucu olduğu gibi kalır, böylece "
      'yazım hatası satırı kırmak yerine notta görünür.';
  @override
  String get templateHelpValuesTitle => 'Değerler';
  @override
  String get templateHelpTitleBody => 'Notun oluşturulduğu isim.';
  @override
  String get templateHelpDateBody =>
      'Bugün ve şu anki saat. İkisi de biçim alır: {{date:DD/MM/YYYY}}.';
  @override
  String get templateHelpNowBody => 'Tarih ve saat birlikte.';
  @override
  String get templateHelpUuidBody => 'Her gösterimde farklı yeni kimlik.';
  @override
  String get templateHelpCounterBody =>
      'İsim başına artan, yeniden başlatmalar arasında saklanan sayı: '
      'ilk not 1, sonraki 2 yazar. Aynı isim tek bir notta aynı sayıyı '
      'yazar. |pad:3 ile birleştirin.';
  @override
  String get templateHelpCursorBody =>
      'Not oluşturulurken imleci buraya koyar; kısmın kendisi yazılmaz. '
      'İlk kısmı kazanır, filtreler olmadan, yalnızca yeni notlar — ve '
      'otomatik odaklama kapalı olsa bile klavye açılır.';
  @override
  String get templateHelpDatesTitle => 'Tarih yazımı';
  @override
  String get templateHelpDatesBody =>
      'Bunlar biçimdeki tarih parçalarını temsil eder. Geri kalan her '
      'şey olduğu gibidir ve düz karakterlerdeki metin de olduğu gibidir. '
      'Ay ve gün adları uygulamanın dilini takip eder.';
  @override
  String get templateHelpYear => 'yıl: 2026, 26';
  @override
  String get templateHelpMonth => 'ay: 03, 3, Mart, Mar';
  @override
  String get templateHelpDay => 'gün: 09, 9, Pazartesi, Paz';
  @override
  String get templateHelpTime => 'saat, dakika, saniye';
  @override
  String get templateHelpWeek => 'ISO hafta ve çeyrek: 11, 11, 1';
  @override
  String get templateHelpFiltersTitle => 'Filtreler';
  @override
  String get templateHelpFiltersBody =>
      'Değer, soldan sağa uygulanan filtrelerle izlenebilir.';
  @override
  String get templateHelpCaseBody =>
      'Büyük, küçük ve her kelimenin ilk harfi büyük — büyük yazdığınız '
      'kelime değişmez kalır.';
  @override
  String get templateHelpSlugBody =>
      'Bağlantılar için metin biçimi, wikilink oluşturmak için.';
  @override
  String get templateHelpPadBody =>
      'Sonu kısaltır. Genişliğe kadar sıfırlarla doldurur. Değer boşsa '
      'yedek kullanır.';
  @override
  String get templateHelpShiftBody =>
      'Tarihi gün, hafta, ay veya yıl kadar kaydırır — gelecek haftanın '
      'sunumu, geçen ayın arşivi.';
  @override
  String get templateHelpSnapBody =>
      'Tarihi haftanın, ayın veya yılın başına veya sonuna sabitler.';
  @override
  String get templateHelpAskTitle => 'Size soran bir şey';
  @override
  String get templateHelpAskBody =>
      'Not oluşturulmadan önce bir form görünür, soru başına bir alan — '
      've şablon isterse geri bağlantı için bir alan da. Aynı isim iki '
      'kez tek sorudur, cevabı tüm gösterimleri doldurur — klasör ve '
      'dosya adı dahil.';
  @override
  String get templateHelpAskFieldBody =>
      'Yazma alanı. İki çift yıldızdan sonraki metin, onunla başlayan '
      'şeydir.';
  @override
  String get templateHelpChoiceBody => 'Virgülle ayrılmış listeden seçim.';
  @override
  String get templateHelpWhereTitle => 'Not nereye gider';
  @override
  String get templateHelpWhereBody =>
      'Bu metin değildir: talimatlardır ve şablonun kendi '
      "frontmatter'ındaki niman: bloğunda yaşar. Blok uygulanır ve sonra "
      'kaldırılır, böylece notta asla görünmez. Değerleri yer tutucular '
      'içerebilir.';
  @override
  String get templateHelpFolderBody =>
      'Notun oluşturulduğu klasör, yoksa oluşturulur. Yoksa not '
      'olduğunuz yere gider.';
  @override
  String get templateHelpFilenameBody =>
      'Notun adı. Bunu beyan eden şablon isim sorulmaz.';
  @override
  String get templateHelpAppendBody =>
      'Not zaten varsa ona ekler, ikinciyi oluşturmak yerine. Bu, bir '
      'ayın tartışmasını tek dosya yapar.';
  @override
  String get templateHelpOpenBody =>
      'Not hazır olduktan sonra ne olur: düzenleyici (varsayılan), '
      'önizleme veya hiçbir şey — not vurgulanır ve olduğunuz yerde '
      'kalırsınız.';
  @override
  String get templateHelpAroundTitle => 'Nereden gelir';
  @override
  String get templateHelpParentBody =>
      'Formda seçilen not, ekrandaki olanı önerir. Ona geri bağlantı '
      'için [[{{parent}}]] yazın.';
  @override
  String get templateHelpFolderValueBody => 'Notun gittiği klasör.';
  @override
  String get templateHelpClipboardBody =>
      'Pano da ne var ve not oradan başlarsa düzenleyicinin seçimi.';
  @override
  String get templateHelpIncludeTitle => 'Parça yeniden kullanımı';
  @override
  String get templateHelpIncludeBody =>
      'Başka bir şablonu gömer, böylece on şablon aynı kontrol '
      'listesini paylaşabilir. Önce şablon klasöründe aranır, .md '
      'atlanabilir. Soruları aynı forma eklenir.';
  @override
  String get templateHelpExampleTitle => 'Hepsi birlikte';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ $path şablonu yok';
  @override
  String includeCycle(String path) => '⚠ $path kendini içeriyor';
  @override
  String includeTooDeep(String path) => '⚠ $path çok derin iç içe';
  @override
  String frontmatterInvalid(String reason) => 'Frontmatter okunamadı: $reason';
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      "“$template”ın frontmatter'ı okunamadı, bu yüzden klasörü ve "
      'dosya adı hiçbir şey yapmadı: $reason';
  @override
  String get templatePickerTitle => 'Şablon seç';
  @override
  String templatePickerEmpty(String folder) =>
      'Henüz şablon yok. $folder/ içine bir not koyun, biri olsun.';

  // Tree actions.
  @override
  String get actionPin => 'Sabitle';
  @override
  String get actionUnpin => 'Sabitlemeyi kaldır';
  @override
  String get pinToWidget => 'Ana ekran widget’ına sabitle';
  @override
  String get pinnedForWidget =>
      'Sabitlendi: şimdi Not widget’ını ana ekrana yerleştir';
  @override
  String get pinWidgetUnavailable =>
      'Ana ekran widget’ları Android’da kullanılabilir';

  // Handing a note's file to the OS (issue #76).
  @override
  String get openInFileManager => 'Dosya yöneticisinde göster';
  @override
  String get openInDefaultApp => 'Varsayılan uygulamada aç';
  @override
  String get newNoteTabTooltip => 'Yeni sekmede yeni not';
  @override
  String get openNotesTooltip => 'Açık notlar';
  @override
  String get closeTabTooltip => 'Kapat';
  @override
  String get openInNewTab => 'Yeni sekmede aç';
  @override
  String get splitRight => 'Sağa böl';
  @override
  String get splitDown => 'Aşağı böl';
  @override
  String get moveToOtherPane => 'Diğer bölmeye taşı';
  @override
  String get openBeside => 'Yanda aç';
  @override
  String get closeAllNotes => 'Tümünü kapat';
  @override
  String get sidePanelTooltip => 'Yan paneli göster veya gizle';
  @override
  String get historyAllVersions => 'Tüm sürümler';
  @override
  String get commandPaletteTitle => 'Komut paleti';
  @override
  String get goToNoteTitle => 'Nota git';
  @override
  String get paletteGroupNote => 'Not';
  @override
  String get paletteGroupEditor => 'Düzenleyici';
  @override
  String get paletteGroupView => 'Görünüm';
  @override
  String get paletteGroupLibrary => 'Kitaplık';
  @override
  String get paletteGroupGoTo => 'Git';
  @override
  String get paletteHint => 'Komut ve not ara';
  @override
  String get paletteNoResults => 'Eşleşen yok';
  @override
  String get paletteCommands => 'Komutlar';
  @override
  String get paletteNotes => 'Notlar';
  @override
  String get paletteFooter =>
      '↑↓ gezinmek için · ↵ kullanmak için · esc kapatmak için';
  @override
  String get zenMode => 'Zen modu';
  @override
  String get zenModeEnter => 'Zen moduna gir';
  @override
  String get zenModeLeave => 'Zen modundan çık';
  @override
  String get keySpace => 'Boşluk';
  @override
  String get keyEnter => 'Enter';
  @override
  String get keyTab => 'Tab';
  @override
  String get keyEscape => 'Esc';
  @override
  String get keyBackspace => 'Geri al tuşu';
  @override
  String get keyDelete => 'Delete';
  @override
  String get keyArrowUp => 'Yukarı';
  @override
  String get keyArrowDown => 'Aşağı';
  @override
  String get keyArrowLeft => 'Sol';
  @override
  String get keyArrowRight => 'Sağ';
  @override
  String get keyHome => 'Home';
  @override
  String get keyEnd => 'End';
  @override
  String get keyPageUp => 'Page Up';
  @override
  String get keyPageDown => 'Page Down';
  @override
  String get keyInsert => 'Insert';
  @override
  String get shortcutNone => 'Kısayol yok';
  @override
  String get shortcutRestoreDefaults => 'Varsayılanları geri yükle';
  @override
  String get shortcutRestoreDefaultsConfirm =>
      "Tüm kısayollar Niman'ın sunduğu hâline döndürülsün mü?";
  @override
  String get shortcutRevert => 'Varsayılana dön';
  @override
  String get shortcutClear => 'Kısayolu kaldır';
  @override
  String get shortcutCapturePrompt =>
      "Tuşlara basın. Esc ve Tab da kaydedilir: çıkış İptal'dir.";
  @override
  String get shortcutCaptureNeedsModifier =>
      'Ctrl, Alt veya Meta ekleyin: tek başına bir tuş yazmak içindir.';
  @override
  String get shortcutMove => 'Taşı';
  @override
  String get shortcutUseAnyway => 'Yine de kullan';
  @override
  String get shortcutUndo => 'Geri al';
  @override
  String get shortcutRedo => 'Yinele';
  @override
  String get shortcutChange => 'Kısayolu değiştir';
  @override
  String shortcutCaptureTitle(String command) => '$command için tuşlar';
  @override
  String shortcutConflict(String keys, String other) =>
      '$keys zaten $other komutunun. Buraya taşınsın mı? $other kısayolsuz '
      'kalacak.';
  @override
  String shortcutTakesEditorKey(String keys, String what) =>
      '$keys metin alanlarında ve düzenleyicide $what da demek. Orada '
      'komutunuz onu alacak.';
  @override
  String get openFileMissing => 'Bu notun dosyası diskte yok';
  @override
  String get openFileFailed => 'Bu not Niman dışında açılamadı';

  @override
  String get movedToTrash => 'Çöp kutusuna taşındı';
  @override
  String get deletedMessage => 'Silindi';
  @override
  String deleteToTrashConfirm(String name) =>
      '$name .trash/ klasörüne taşınacak';
  @override
  String deleteForeverConfirm(String name) => '$name kalıcı olarak silinecek';
  @override
  String get chooseDestination => 'Hedefi seç';
  @override
  String get libraryRoot => 'Kütüphane kökü';
  @override
  String moveTitle(String name) => '$name taşınacak';
  @override
  String headingLevelLabel(int level) => '$level düzeyi başlık';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty =>
      'Henüz hızlı not yok. Kalıcı bir not seçin veya yeni oluşturun — '
      'hızlı not burada açılır.';
  @override
  String get quickNoteChooseAction => 'Not seç…';
  @override
  String get quickNoteCreateAction => 'Yeni not oluştur…';
  @override
  String get quickNoteNewTitle => 'Yeni hızlı not';
  @override
  String get quickNotePickerTitle => 'Hızlı not seç';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => 'Yeni klasör';
  @override
  String get folderPickerEmpty => 'Henüz klasör yok';
  @override
  String get listFolderTitle => 'Liste klasörü';
  @override
  String get attachmentsFolderTitle => 'Ekler klasörü';

  // Trash (M1).
  @override
  String get trashEmpty => 'Çöp kutusu boş';
  @override
  String get trashEmptyAction => 'Çöp kutusunu boşalt';
  @override
  String get trashEmptyConfirm =>
      "Bu, çöp klasöründeki her şeyi kalıcı olarak siler, Niman'ın "
      'oraya koymadığı öğeler dahil.';
  @override
  String trashDeleteConfirm(String name) =>
      '$name kalıcı olarak silinecek (dönüş yok)';
  @override
  String get trashDeletePermanently => 'Kalıcı olarak sil';

  // The open/create library screen.
  @override
  String get openLibraryIntro =>
      'Markdown notları olan bir klasörü kütüphaneniz olarak açın';
  @override
  String get openLibraryExisting => 'Mevcut olanı aç';
  @override
  String get openLibraryCreate => 'Yeni oluştur';
  @override
  String get openLibraryCreateTitle => 'Yeni kütüphane oluştur';
  @override
  String get openLibraryFolderName => 'Klasör adı';
  @override
  String get openLibraryChooseFolder => 'Kütüphane klasörünü seç';
  @override
  String get openLibraryChooseParent =>
      'Kütüphanenin oluşturulacağı klasörü seç';
  @override
  String get openLibraryUnsupported =>
      'Bu klasör desteklenmiyor. Bir depolama klasörü seçin.';
  @override
  String indexingCount(int done, int total) => "$total notun $done'ı";

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => 'Kütüphaneleriniz';
  @override
  String get libraryUnreachable => 'Ulaşılamıyor';
  @override
  String get libraryOpenedToday => 'Bugün açıldı';
  @override
  String get libraryOpenedYesterday => 'Dün açıldı';
  @override
  String libraryOpenedDaysAgo(int days) => '$days gün önce açıldı';
  @override
  String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return '${when.year}-$m-$d tarihinde açıldı';
  }

  @override
  String get libraryOpenNow => 'Şimdi aç';
  @override
  String get switchLibraryTitle => 'Kütüphaneyi değiştir';
  @override
  String get libraryForget => 'Unut';
  @override
  String libraryForgetTitle(String name) => '“$name” unutulsun mu?';
  @override
  String get libraryForgetExplained =>
      'Bu listeden kaybolur. Klasör, notlar ve içindeki kütüphane '
      'ayarları değişmez; yeniden açınca geri döner.';

  // Android storage access.
  @override
  String get storageAccessAction => 'Dosya erişimine izin ver';
  @override
  String get storageAccessNeeded =>
      'Niman, “Tüm dosyalara erişim” olmadan notlarınızı okuyamaz. Bir '
      'kütüphane açmak için izin verin.';
  @override
  String get storageAccessExplained =>
      'Niman notlarınızı düz dosyalar olarak okur, bu yüzden Android '
      'tüm dosyalara erişime izin vermelidir. Hiçbir şey yüklenmez, '
      'yalnızca seçtiğiniz kütüphane klasörü okunur.';
  @override
  String folderAccessDenied(Object error) =>
      'Sistem klasöre erişim vermedi: $error';
  @override
  String folderPickFailed(Object error) => 'Klasör seçilemedi: $error';

  // Settings screen rows and messages.
  @override
  String get settingsTitle => 'Ayarlar';
  @override
  String get libraryPathTitle => 'Kütüphane yolu';
  @override
  String get reindexTitle => 'Dekoru şimdi yeniden oluştur';
  @override
  String get reindexDone => 'Dekor yeniden oluşturuldu';
  @override
  String get closeLibraryTitle => 'Kütüphaneyi kapat';
  @override
  String get exportLogTitle => 'Hata ayıklama kayıtlarını dışa aktar';
  @override
  String get exportLogSubtitle =>
      'Kaydedilen olayları seçeceğiniz dosyaya kaydet';
  @override
  String get exportLogEmpty => 'Hata ayıklama kayıt tamponu boş';
  @override
  String get quickNoteUnset => 'Henüz ayarlanmadı';
  @override
  String exportLogDone(Object target) =>
      'Kayıtlar $target konumuna dışa aktarıldı';
  @override
  String exportLogFailed(Object error) => 'Dışa aktarma başarısız: $error';

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) =>
      '“$term” tam kelime eşleşmesi bulunamadı';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      '“$term”ın $occurrences gösterimi $notes notta değiştirildi';
  @override
  String replaceSkipped(int skipped) => ' ($skipped açık not atlandı)';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      '“$term” için tam kelime eşleşmesi yok'
      '${only == null ? ' bulunamadı' : ' $only içinde bulundu'}';

  // About (issue #80).
  @override
  String get settingsSectionAbout => 'Hakkında';
  @override
  String get versionTitle => 'Sürüm';
  @override
  String get changelogTitle => 'Değişiklik geçmişi';
  @override
  String get changelogEmpty => 'Değişiklik geçmişi girişleri yok';
  @override
  String changelogWhatsNew(String version) => 'Sürüm $version yenilikleri';

  // Note history (issues #13, #55, #67).
  @override
  String get noteHistoryTitle => 'Geçmiş';
  @override
  String get noteMenuTooltip => 'Not işlemleri';
  @override
  String get historyCurrentVersion => 'Geçerli sürüm';
  @override
  String get historyCurrentSubtitle => 'Notun şu anki hâli';
  @override
  String get historyToday => 'Bugün';
  @override
  String get historyYesterday => 'Dün';
  @override
  String get historyReasonSession => 'düzenleme öncesi';
  @override
  String get historyReasonInterval => 'düzenleme sırasında';
  @override
  String get historyReasonRestore => 'geri yükleme öncesi';
  @override
  String get historyReasonSync => 'eşitleme öncesi';
  @override
  String get historyReasonReplace => 'değiştirme öncesi';
  @override
  String get historyReasonUnknown => 'kurtarılan';
  @override
  String get historySyncBase => 'eşitleme tabanı';
  @override
  String get historyEmpty =>
      'Henüz sürüm yok. Niman, notu düzenlemeye başladığınızda bir sürüm, '
      'ardından siz yazarken en fazla birkaç dakikada bir yeni sürüm saklar.';
  @override
  String historyKept(int kept, int limit) =>
      'Saklanan sürümler: $kept / $limit';
  @override
  String get historyBaseKept => 'Eşitleme tabanı sınırın ötesinde de saklanır.';
  @override
  String get historyOff => 'Bu kütüphanede geçmiş kapalı (Ayarlar, Kütüphane).';
  @override
  String get historyLoadFailed => 'Geçmiş okunamadı';
  @override
  String get historyCompareSubtitle => 'Geçerli sürümle karşılaştırıldı';
  @override
  String get historyTabChanges => 'Değişiklikler';
  @override
  String get historyTabVersion => 'Sürüm';
  @override
  String get historyNoChanges => 'Metin geçerli sürümle aynı.';
  @override
  String get historyRestoreAction => 'Bu sürümü geri yükle';
  @override
  String historyRestoreConfirmTitle(String when) =>
      '$when tarihli sürüm geri yüklensin mi?';
  @override
  String get historyRestoreConfirmBody =>
      'Geçerli metin önce geçmişe kaydedilir, böylece her zaman geri '
      'dönebilirsiniz.';
  @override
  String get historyRestoreConfirm => 'Geri yükle';
  @override
  String historyRestored(String when) => '$when tarihli sürüm geri yüklendi';
  @override
  String get historyRestoreFailed => 'Sürüm geri yüklenemedi';
  @override
  String get actionUndo => 'Geri al';
  @override
  String diffLineRange(int start, int end) => 'Satır $start–$end';
  @override
  String diffLineSingle(int line) => 'Satır $line';
  @override
  String diffUnchanged(int count) => '$count değişmemiş satır';
  @override
  String get historyTakeHunk => 'Burada geri al';
  @override
  String historyRestoreSelectedAction(int count) =>
      count == 1 ? '1 değişikliği geri al' : '$count değişikliği geri al';
  @override
  String get historyRestoreSelectedConfirmBody =>
      'Seçtiğin değişiklikler bu sürümün metnine döner. Notun şu anki hâli '
      'önce sürüm olarak saklanır, böylece bunu geri alabilirsin.';
  @override
  String get historyNoteChangedReloaded =>
      'Sen buradayken not değişti — karşılaştırma yenilendi.';
  @override
  String get historyVersionsTitle => 'Saklanacak sürüm sayısı';
  @override
  String get historyVersionsSubtitle => 'Not başına, .history/ içinde';
  @override
  String historyVersionsValue(int count) => count == 0 ? 'Yok' : '$count';
  @override
  String get historyIntervalTitle => 'Yeni sürümler arasında en az';
  @override
  String get historyIntervalSubtitle =>
      'Yazarken; bir notu düzenlemeye başlamak her zaman bir sürüm saklar';
  @override
  String historyIntervalValue(int minutes) => '$minutes dk';
  @override
  String get settingsSectionTranscription => 'Metne dökme';
  @override
  String get transcriptionModelTitle => 'Model';
  @override
  String get transcriptionModelNone => 'Yok';
  @override
  String get transcriptionLanguageTitle => 'Dil';
  @override
  String get transcriptionLanguageSubtitle =>
      'Kayıtlarınızda konuşulan dil. Dili belirtmek, otomatik algılamadan '
      'daha doğru sonuç verir.';
  @override
  String transcriptionLanguageApp(String language) =>
      'Uygulamayla aynı ($language)';
  @override
  String get transcriptionLanguageDetect => 'Otomatik algıla';
  @override
  String get transcriptionModelsTitle => 'Metne dökme modelleri';
  @override
  String transcriptionModelsUsed(String size) => '$size kullanılıyor';
  @override
  String get transcriptionModelsInstalled => 'İndirilenler';
  @override
  String get transcriptionModelsDownloading => 'İndiriliyor';
  @override
  String get transcriptionModelsAvailable => 'Kullanılabilir';
  @override
  String get transcriptionModelsFooter =>
      'Modeller bu cihazda uygulamanın depolama alanında kalır. Kitaplığa '
      'kopyalanmaz ve eşitlenmez.';
  @override
  String get transcriptionModelDefault => 'Varsayılan';
  @override
  String get transcriptionModelSlow => 'Yavaş';
  @override
  String get transcriptionModelHintTiny => 'En hızlı, en az doğru';
  @override
  String get transcriptionModelHintBase => 'Hız ve doğruluk arasında iyi denge';
  @override
  String get transcriptionModelHintSmall =>
      'Daha doğru, yaklaşık 3× daha yavaş';
  @override
  String get transcriptionModelHintMedium => 'Çok doğru, telefonda yavaş';
  @override
  String get transcriptionModelHintLarge => 'En doğru, çok bellek gerektirir';
  @override
  String get transcriptionModelDownload => 'İndir';
  @override
  String transcriptionModelDeleteTitle(String model) =>
      '$model modeli silinsin mi?';
  @override
  String transcriptionModelDeleteBody(String size) =>
      'Bu işlem $size yer açar. Modeli daha sonra yeniden indirebilirsiniz.';
  @override
  String get transcriptionModelFailed =>
      'İndirme başarısız oldu. Bağlantınızı kontrol edip yeniden deneyin.';
  @override
  String get actionRetry => 'Yeniden dene';
  @override
  String get decimalSeparator => ',';
  @override
  String get transcriptionModelRetrying => 'Bağlantı koptu, yeniden deneniyor…';
  @override
  String transcriptionModelInterrupted(String progress) =>
      '$progress noktasında duraklatıldı';
  @override
  String get actionResume => 'Devam et';
  @override
  String get audioTranscribe => 'Metne dök';
  @override
  String get audioTranscribeUnsupported => 'Bu cihazda yalnızca WAV kayıtları';
  @override
  String get transcriptionQueued => 'Sırada';
  @override
  String get transcriptionPreparing => 'Ses hazırlanıyor…';
  @override
  String transcriptionRunning(int percent) => 'Metne dökülüyor… %$percent';
  @override
  String transcriptionWaitingForModel(String model, int percent) =>
      '$model indiriliyor · %$percent';
  @override
  String get transcriptionSaved => 'Metin açıklamaya eklendi';
  @override
  String get transcriptionNoSpeech => 'Bu kayıtta konuşma algılanmadı';
  @override
  String get transcriptionFailed => 'Metne dökme başarısız oldu';
  @override
  String get transcriptionPickModelTitle => 'Bir model seçin';
  @override
  String get transcriptionPickModelBody =>
      'Metne dökme bu cihazda yapılır ve kayıt hiçbir yere gönderilmez. Model '
      'yalnızca bir kez indirilir.';
  @override
  String get transcriptionPickModelAction => 'İndir ve metne dök';
  @override
  String get transcriptionModelRecommended => 'Önerilen';
  @override
  String get transcriptionExistingTitle => 'Bu kaydın zaten bir açıklaması var';
  @override
  String get transcriptionExistingBody =>
      'Metinle değiştirilsin mi, yoksa metin altına mı eklensin?';
  @override
  String get transcriptionAppend => 'Altına ekle';
  @override
  String get transcriptionReplace => 'Değiştir';
  @override
  String get settingsSectionSync => 'Eşitleme';
  @override
  String get syncWebDavTitle => 'WebDAV';
  @override
  String get syncNotConfigured => 'Bu kütüphane için ayarlanmadı';
  @override
  String get syncNeverSynced => 'Hiç eşitlenmedi';
  @override
  String syncLastSynced(String when) => 'Eşitlendi: $when';
  @override
  String get syncRunning => 'Eşitleniyor…';
  @override
  String syncScreenSubtitle(String library) => 'Kütüphane: $library';
  @override
  String get syncUrlLabel => 'Klasör adresi';
  @override
  String get syncUrlRequired => 'Sunucu adresini girin';
  @override
  String get syncUrlHint =>
      'Klasör mevcut olmalı. Adresi sunucunun gösterdiği gibi '
      'kopyalayın.';
  @override
  String get syncHttpWarning =>
      'Şifrelenmemiş bağlantı: VPN üzerinden veya yerel ağda '
      'sorun değil.';
  @override
  String get syncUserLabel => 'Kullanıcı';
  @override
  String get syncUserHint => 'Sunucu kimlik bilgisi istemiyorsa boş bırakın.';
  @override
  String get syncPasswordLabel => 'Parola';
  @override
  String get syncPasswordHint =>
      'Kütüphane dosyalarında değil, bu cihazın anahtar '
      'zincirinde saklanır.';
  @override
  String get syncPasswordKeepHint =>
      'Kayıtlı parolayı korumak için boş bırakın.';
  @override
  String get syncShowPassword => 'Parolayı göster';
  @override
  String get syncHidePassword => 'Parolayı gizle';
  @override
  String get syncTestAction => 'Bağlantıyı test et';
  @override
  String get syncTesting => 'Test ediliyor…';
  @override
  String get syncRetargetWarning =>
      'Yeni bir adres veya kullanıcıyla sonraki eşitleme, ilk '
      'eşitleme olarak baştan başlar.';
  @override
  String get syncTestOk => 'Bağlantı çalışıyor';
  @override
  String get syncModeFull => 'Tam mod';
  @override
  String get syncModeCompatible => 'Uyumlu mod';
  @override
  String syncTestOkSubtitle(String mode, int ms) => '$mode · $ms ms';
  @override
  String get syncCapBasic => 'Okuma, yazma ve silme';
  @override
  String get syncCapEtags => 'Dosya parmak izleri (ETag)';
  @override
  String get syncCapNoEtags => 'Dosya parmak izi yok (ETag)';
  @override
  String get syncCapNoEtagsDetail =>
      'Boyutu ve tarihi karşılaştırır; emin olamazsa yeniden '
      'indirir';
  @override
  String get syncCapGuarded => 'Korumalı yazma';
  @override
  String get syncCapUnguarded => 'Korumasız yazma';
  @override
  String get syncCapUnguardedDetail =>
      'Yazmadan hemen önce sunucudaki dosyayı denetler';
  @override
  String get syncCapMove => 'Yeniden yüklemeden yeniden adlandırır';
  @override
  String get syncCapNoMove => 'Sunucuda yeniden adlandırma yok';
  @override
  String get syncCapNoMoveDetail =>
      'Yeniden adlandırma, silme ve yeni yüklemeye dönüşür';
  @override
  String get syncCompatibleNote =>
      'Uyumlu modda eşitleme aynı şekilde çalışır, yalnızca '
      'birkaç istek daha gönderilir.';
  @override
  String get syncTestInvalidUrl => 'Geçerli bir adres değil';
  @override
  String get syncTestInvalidUrlHint =>
      'İçinde kullanıcı veya parola olmadan bir http:// ya da '
      'https:// adresi girin.';
  @override
  String get syncTestOffline => 'Sunucuya ulaşılamıyor';
  @override
  String get syncTestOfflineHint =>
      'VPN açık mı? 10.x veya 192.168.x adresi yalnızca aynı '
      'ağdan çalışır.';
  @override
  String get syncTestAuth => 'Kullanıcı veya parola reddedildi';
  @override
  String get syncTestAuthHint => 'Kontrol edip yeniden test edin.';
  @override
  String get syncTestNotFound => 'Klasör mevcut değil';
  @override
  String get syncTestNotFoundHint => 'Sunucuda oluşturun veya adresi düzeltin.';
  @override
  String get syncTestUnsupported => 'WebDAV klasörü değil';
  @override
  String get syncTestUnsupportedHint =>
      'Sunucu yanıt veriyor, ama WebDAV olarak değil.';
  @override
  String get syncTestFailed => 'Test başarısız oldu';
  @override
  String get syncNowAction => 'Şimdi eşitle';
  @override
  String get syncSectionServer => 'Sunucu';
  @override
  String get syncServerRow => 'Adres, kullanıcı ve parola';
  @override
  String get syncRetestTitle => 'Sunucuyu yeniden test et';
  @override
  String syncProbedAgo(String when) => 'Son test: $when';
  @override
  String get syncDisconnectTitle => 'Bu kütüphanenin bağlantısını kes';
  @override
  String get syncDisconnectSubtitle => 'Dosyalar burada ve sunucuda kalır';
  @override
  String get syncDisconnectConfirmTitle => 'Eşitleme bağlantısı kesilsin mi?';
  @override
  String get syncDisconnectConfirmBody =>
      'Bu kütüphane bu cihazda artık eşitlenmez. Ne burada ne '
      'sunucuda hiçbir dosya silinmez. Yeniden bağlarsanız ilk '
      'eşitleme baştan başlar.';
  @override
  String get syncDisconnectConfirm => 'Bağlantıyı kes';
  @override
  String get syncFirstTitle => 'İlk eşitleme';
  @override
  String get syncFirstIntro =>
      'Kütüphaneyi sunucudaki klasörle karşılaştırdım:';
  @override
  String get syncFirstUpload => 'Yüklenecek';
  @override
  String get syncFirstDownload => 'İndirilecek';
  @override
  String get syncFirstBoth => 'Her iki tarafta';
  @override
  String get syncFirstBothHint =>
      'Aynı olanlar: aktarım yok. Farklı olanlar: çözülecek';
  @override
  String get syncFirstNoDelete =>
      'İlk eşitleme ne burada ne sunucuda hiçbir şey silmez.';
  @override
  String get syncStartAction => 'Başlat';
  @override
  String syncMassTrashTitle(int count) =>
      '$count dosya çöp kutusuna taşınsın mı?';
  @override
  String syncMassTrashBody(int count, int total) =>
      'Eşitlenen $total dosyadan $count tanesi sunucuda yok. Bu '
      'genellikle yanlış bir adres, bağlanmamış bir NAS diski ya '
      'da yanlışlıkla boşaltılmış bir klasör demektir.';
  @override
  String get syncMassTrashHint =>
      'Bunları gerçekten başka bir cihazda sildiyseniz '
      'onaylayın: burada çöp kutusuna gidecekler.';
  @override
  String get syncMassTrashConfirm => 'Çöp kutusuna taşı';
  @override
  String syncMassDeleteTitle(int count) =>
      '$count dosya sunucudan silinsin mi?';
  @override
  String syncMassDeleteBody(int count, int total) =>
      'Eşitlenen $total dosyadan $count tanesi burada yok. '
      'Bunları siz silmediyseniz iptal edin ve kütüphane '
      'klasörünü kontrol edin.';
  @override
  String get syncMassDeleteConfirm => 'Sunucudan sil';
  @override
  String get syncTooltip => 'Eşitle';
  @override
  String get syncStageConnecting => 'Sunucuya bağlanılıyor…';
  @override
  String get syncStageComparing => 'Sunucuyla karşılaştırılıyor…';
  @override
  String syncStageApplying(int done, int total) =>
      'Eşitleniyor · $done / $total';
  @override
  String get syncStatusWarnings => 'Uyarılarla eşitlendi';
  @override
  String syncConflictsHeader(int count) =>
      'Burada ve sunucuda değişti · $count';
  @override
  String get syncConflictHint => 'İki sürüme de dokunulmadı';
  @override
  String get syncResolveAction => 'Çöz';
  @override
  String syncFailuresHeader(int count) => 'Eşitlenmedi · $count';
  @override
  String get syncFailuresHint => 'Sonraki eşitlemede yeniden denenecek';
  @override
  String get syncAbortAuth => 'Parola sunucu tarafından reddedildi';
  @override
  String get syncAbortMissingPassword => 'Kayıtlı parola yok';
  @override
  String get syncAbortOffline => 'Sunucuya ulaşılamıyor';
  @override
  String get syncAbortRemoteMissing => 'Sunucudaki klasör artık yok';
  @override
  String get syncAbortUnsupported => 'Sunucu artık WebDAV olarak çalışmıyor';
  @override
  String get syncAbortFailed => 'Eşitleme başarısız oldu';
  @override
  String get syncAbortNotConfirmed => 'Eşitleme iptal edildi';
  @override
  String get syncAbortNothingTouched =>
      'Hiçbir dosyaya dokunulmadı. Değişiklikleriniz bir sonraki '
      'başarılı eşitlemeye kadar burada kalır.';
  @override
  String syncLastSuccess(String when) => 'Son başarılı eşitleme: $when';
  @override
  String get syncNoSuccessYet => 'Henüz başarılı eşitleme yok';
  @override
  String get syncUpdatePasswordAction => 'Parolayı güncelle';
  @override
  String get syncRetryAction => 'Yeniden dene';
  @override
  String get syncOpenSettingsAction => 'Ayarlar';
  @override
  String get syncCloseAction => 'Kapat';
  @override
  String get syncDoneSnack => 'Eşitlendi';
  @override
  String syncTrashedSnack(int count) => count == 1
      ? 'Eşitlendi · başka yerde silinen 1 dosya çöp kutusunda'
      : 'Eşitlendi · başka yerde silinen $count dosya çöp kutusunda';
  @override
  String syncConflictsSnack(int count) => count == 1
      ? 'Eşitlendi · çözülecek 1 çakışma'
      : 'Eşitlendi · çözülecek $count çakışma';
  @override
  String get syncShowAction => 'Göster';
  @override
  String get syncConflictTitle => 'Çakışmayı çöz';
  @override
  String get syncConflictLegend =>
      '− ile işaretli satırlar sunucunun, + ile işaretli '
      'satırlar bu cihazın.';
  @override
  String get syncConflictBinary =>
      'Metin dosyası değil: hangi kopyanın kalacağını seçin.';
  @override
  String get syncConflictKeepNote =>
      'Tutmadığınız kopya notun geçmişinde kalır.';
  @override
  String get syncKeepLocal => 'Bu cihazdakini tut';
  @override
  String get syncKeepRemote => 'Sunucudakini tut';
  @override
  String get syncConflictIdentical => 'İki sürüm aynı';
  @override
  String get syncConflictLoadFailed => 'İki sürüm de okunamadı';
  @override
  String get syncResolveFailed => 'Çakışma çözülemedi';
  @override
  String get syncResolved => 'Çakışma çözüldü';
  @override
  String get syncSectionWhen => 'Ne zaman eşitlensin';
  @override
  String get syncAutoTitle => 'Otomatik olarak';
  @override
  String get syncAutoSubtitle =>
      'Düzenlemelerden sonra, açılışta ve belirli aralıklarla';
  @override
  String get syncIntervalTitle => 'Sunucuyu denetleme sıklığı';
  @override
  String get syncIntervalSubtitle => 'Yalnızca uygulama açıkken';
  @override
  String get syncIntervalDialogBody =>
      'Uygulama açıkken diğer cihazlarda yapılan değişiklikleri görmek '
      'için. “Hiçbir zaman” seçiliyse yalnızca düzenlemelerden sonra ve '
      'açılışta.';
  @override
  String syncIntervalMinutes(int count) => '$count dakikada bir';
  @override
  String get syncIntervalNever => 'Hiçbir zaman';
  @override
  String get syncWifiOnlyTitle => 'Yalnızca Wi-Fi';
  @override
  String get syncWifiOnlySubtitle => 'Mobil veride yalnızca elle eşitle';
  @override
  String syncPendingChanges(int count) => '$count değişiklik bekliyor';
  @override
  String syncRetryIn(String wait) => '$wait sonra yeniden denenecek';
  @override
  String syncWaitSeconds(int seconds) => '$seconds sn';
  @override
  String syncWaitMinutes(int minutes) => '$minutes dk';
  @override
  String get syncWaitingForWifi => 'Wi-Fi bekleniyor';
  @override
  String get syncWaitingForNetwork => 'Bağlantı bekleniyor';
  @override
  String get syncMobileDataHint =>
      '“Şimdi eşitle” yine de mobil veri kullanır.';
  @override
  String get syncQueueKeptHint =>
      'Değişiklikler, uygulamayı kapatsanız bile burada kalır ve sunucu '
      'yanıt verdiğinde kendiliğinden gönderilir.';
  @override
  String get syncAutoPaused => 'Otomatik eşitleme duraklatıldı';
  @override
  String get syncPausedAuthHint =>
      'Parolayı güncellediğinizde veya elle eşitlediğinizde devam eder.';
  @override
  String get syncPausedServerHint =>
      'Adresi düzelttiğinizde veya elle eşitlediğinizde devam eder.';
  @override
  String get syncPausedConfirmHint =>
      '“Şimdi eşitle” nelerin kaldırılacağını gösterir ve önce onayınızı '
      'ister.';
  @override
  String get syncNeedsConfirmation => 'Onayınız bekleniyor';
  @override
  String get syncMergeIntro =>
      'Örtüşmeyen düzenlemeler zaten birleştirildi; örtüşenlerde '
      'neyin kalacağını seçin.';
  @override
  String get syncMergeClean =>
      'İki sürüm kendiliğinden birleşiyor: hiçbir yerde örtüşme yok.';
  @override
  String get syncMergeNoBase =>
      'Üzerinde birleştirilecek ortak bir sürüm yok, bu yüzden '
      'dosyanın tamamı seçilmeli.';
  @override
  String syncMergeOverlap(int index, int total) => 'Örtüşme $index / $total';
  @override
  String get syncMergeFromLocal => 'Bu cihazdan';
  @override
  String get syncMergeFromRemote => 'Sunucudan';
  @override
  String get syncMergeRemovedLines => 'Kaldırılan satırlar';
  @override
  String get syncMergeKeepLocal => 'Benimki';
  @override
  String get syncMergeKeepRemote => 'Sunucununki';
  @override
  String get syncMergeKeepBoth => 'İkisi de';
  @override
  String get syncMergeSave => 'Birleştirmeyi kaydet';
  @override
  String get syncMergeKeepWhole => 'Ya da tek bir tam kopya tut';
}
