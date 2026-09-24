// The French strings.
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class FrenchStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];
  @override
  List<String> get monthNamesShort => const [
    'janv.',
    'févr.',
    'mars',
    'avr.',
    'mai',
    'juin',
    'juil.',
    'août',
    'sept.',
    'oct.',
    'nov.',
    'déc.',
  ];
  @override
  List<String> get weekdayNames => const [
    'lundi',
    'mardi',
    'mercredi',
    'jeudi',
    'vendredi',
    'samedi',
    'dimanche',
  ];
  @override
  List<String> get weekdayNamesShort => const [
    'lun.',
    'mar.',
    'mer.',
    'jeu.',
    'ven.',
    'sam.',
    'dim.',
  ];

  // Settings: editor toggles.
  @override
  String get trashTitle => 'Corbeille';
  @override
  String get trashSubtitle =>
      'Les éléments supprimés vont dans .trash/ (off = suppression '
      'définitive)';
  @override
  String get trashAutoEmptyTitle => 'Vidage automatique de la corbeille';
  @override
  String get trashAutoEmptySubtitle =>
      'Les suppressions anciennes disparaissent à l’ouverture';
  @override
  String trashAutoEmptyValue(int days) => days == 0
      ? 'Jamais'
      : days == 1
      ? '1 jour'
      : '$days jours';
  @override
  String get debugLogsTitle => 'Journaux de débogage';
  @override
  String get debugLogsSubtitle =>
      'Enregistre les événements de l’app dans un tampon en mémoire';
  @override
  String get lineNumbersTitle => 'Numéros de ligne';
  @override
  String get lineNumbersSubtitle =>
      'Affiche la colonne des numéros de ligne dans l’éditeur';
  @override
  String get readableLineLengthTitle => 'Longueur de ligne lisible';
  @override
  String get readableLineLengthSubtitle =>
      'Garder le texte de la note dans une colonne centrée plutôt que sur '
      'toute la largeur de la fenêtre';
  @override
  String get noteColumnWidthTitle => 'Largeur de la colonne';
  @override
  String get noteColumnWidthSubtitle =>
      'La largeur de la colonne de la note, en pixels';
  @override
  String noteColumnWidthValue(int pixels) => '$pixels px';
  @override
  String get keyboardOnOpenTitle => 'Clavier à l’ouverture';
  @override
  String get keyboardOnOpenSubtitle =>
      'Affiche le clavier dès qu’une note s’ouvre (off = au premier tap)';
  @override
  String get editorKindSource => 'Source Markdown';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get editorKindSourceSubtitle =>
      'Source Markdown, telle qu\u2019écrite';
  @override
  String get editorKindWysiwygSubtitle =>
      'Texte mis en forme, modifié sur place';
  @override
  String get settingsFolderToCreate => 'à créer';
  @override
  String get settingsSearchHint => 'Rechercher dans les réglages';
  @override
  String settingsSearchResults(int count) =>
      count == 1 ? '1 réglage trouvé' : '$count réglages trouvés';
  @override
  String get settingsToggleOn => 'Activé';
  @override
  String get settingsToggleOff => 'Désactivé';
  @override
  String get settingsPreviewEnabledTitle => 'Aperçu';
  @override
  String get settingsPreviewEnabledSubtitle =>
      'Affiche la note rendue à côté de l’éditeur source';
  @override
  String get switchToWysiwygTooltip => 'Passer à l’éditeur WYSIWYG';
  @override
  String get switchToSourceTooltip => 'Passer à la source Markdown';
  @override
  String get switchToSourceLabel => 'Source';
  @override
  String get switchToWysiwygLabel => 'WYSIWYG';
  @override
  String get wysiwygTooLarge =>
      'Cette note est trop grande pour l’éditeur WYSIWYG. Ouvrez-la dans la '
      'source Markdown.';

  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'Apparence';
  @override
  String get settingsSectionEditor => 'Éditeur';
  @override
  String get settingsSectionLibrary => 'Bibliothèque';
  @override
  String get settingsSectionReminders => 'Rappels';
  @override
  String get settingsSectionShortcuts => 'Clavier';
  @override
  String get keyboardShortcutsTitle => 'Raccourcis clavier';

  // Settings home (issue #104): the groups the areas sit under.
  @override
  String get settingsGroupApp => 'App';
  @override
  String settingsGroupLibrary(String name) => 'Bibliothèque $name';
  @override
  String get settingsGroupLibraryHint =>
      "s'applique uniquement à cette bibliothèque";
  @override
  String get settingsGroupMaintenance => 'Maintenance';

  // Settings home rows.
  @override
  String get settingsAreaFolders => 'Dossiers et chemins';
  @override
  String get settingsAreaTrashHistory => 'Corbeille et chronologie';
  @override
  String get settingsAreaDiagnostics => 'Diagnostic et infos';
  @override
  String get settingsAreaKeyboardDisabled =>
      'Nécessite un clavier physique connecté';
  @override
  String get settingsSectionUpdates => 'Mises à jour';
  @override
  String get autoUpdateTitle => 'Mises à jour automatiques';
  @override
  String get autoUpdateSubtitle =>
      'Vérifie GitHub Releases au lancement et toutes les 6 heures';
  @override
  String get checkForUpdatesTitle => 'Rechercher des mises à jour';
  @override
  String updateAvailableMessage(Object version) =>
      'Niman $version est disponible';
  @override
  String get updateUpToDate => 'Niman est à jour';
  @override
  String get updateCheckFailed => 'Échec de la recherche de mises à jour';
  @override
  String updateSavedTo(Object path) => 'Mise à jour enregistrée dans $path';
  @override
  String get updateInstallerStarted => 'Programme d’installation lancé';
  @override
  String get settingsSectionDiagnostics => 'Diagnostics';
  @override
  String get settingsSpellCheckTitle => 'Vérifier l’orthographe';
  @override
  String get settingsSpellCheckSubtitle =>
      'Souligne les mots mal orthographiés pendant la saisie.';
  @override
  String get spellCheckDictionaryTitle => 'Dictionnaire';
  @override
  String get spellCheckDictionarySystem => 'Par défaut du système';
  @override
  String get spellCheckDictionaryChoiceTitle => 'Choisir les dictionnaires';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      'Choisissez chaque langue dans laquelle cette bibliothèque est '
      'écrite. Un mot est correct si un dictionnaire choisi le connaît ; '
      'sans choix, c’est la locale du système qui décide.';
  @override
  String get spellCheckNoDictionaries =>
      'Aucun dictionnaire trouvé sur ce système.';

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => 'Vérifier l’orthographe';
  @override
  String get spellCheckTitle => 'Orthographe';
  @override
  String get spellCheckEmpty => 'Aucune faute d’orthographe.';
  @override
  String get spellCheckUnavailable =>
      'hunspell n’est pas installé sur ce système.';
  @override
  String get spellCheckNoSuggestions => 'Aucune suggestion';
  @override
  String spellCheckCount(int count) => '$count à relire';
  @override
  String spellCheckLine(int line) => 'ligne $line';
  @override
  String get addWordToDictionary => 'Ajouter au dictionnaire';

  @override
  String indentWidthValue(int spaces) => '$spaces espaces';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => 'Luminosité';
  @override
  String get themeBrightnessSubtitle =>
      'Claire, sombre ou celle réglée sur l’appareil';
  @override
  String get themeBrightnessSystem => 'Système';
  @override
  String get themeBrightnessDay => 'Claire';
  @override
  String get themeBrightnessNight => 'Sombre';
  @override
  String get themeTitle => 'Thème';
  @override
  String get themeSubtitle => 'Les couleurs de l’interface et de la note';
  @override
  String get themePaletteSystem => 'Système';
  // Settings: the themes page (issue #269).
  @override
  String get settingsSectionThemes => 'Thèmes';
  @override
  String get themesInUse => 'Utilisé';
  // Settings: making, renaming, deleting (issue #269).
  @override
  String get themeNewTitle => 'Nouveau thème';
  @override
  String get themeNewName => 'Nom';
  @override
  String get themeNewStartFrom => 'Partir de';
  @override
  String get themeNewRandom => 'Couleurs aléatoires';
  @override
  String get themeNameTaken => 'Un thème portant ce nom existe déjà';
  @override
  String themeDeleteBody(String name) =>
      'Supprimer « $name » ? Ses couleurs seront perdues définitivement.';
  @override
  String get themeDuplicate => 'Dupliquer';
  @override
  String get themeMenuTooltip => 'Actions du thème';
  // Settings: the theme editor (issue #269).
  @override
  String get themeEdit => 'Modifier';
  @override
  String get themeEditorTitle => 'Modifier le thème';
  @override
  String get themeEditorChrome => 'Interface';
  @override
  String get themeEditorMarkdown => 'Markdown';
  @override
  String get themeEditorRolesHint =>
      'Chaque couleur porte le nom que lui donne le fichier exporté';
  @override
  String get themeEditorDiscardTitle => 'Abandonner les modifications';
  @override
  String get themeEditorDiscardBody =>
      'Les couleurs que vous avez modifiées ne seront pas enregistrées';
  @override
  String get themeEditorDiscard => 'Abandonner';
  @override
  String get themeEditorBadColor => 'Utiliser #RRGGBB';
  // Settings: moving a theme in and out (issue #269).
  @override
  String get themeExport => 'Exporter';
  @override
  String themeExportDone(String where) => 'Thème exporté vers $where';
  @override
  String themeFileFailed(String error) =>
      'Le thème n’a pas pu être déplacé : $error';
  @override
  String get themeImport => 'Importer';
  @override
  String get themeImportInvalid => 'Ce fichier n’est pas un thème Niman';
  @override
  String themeImportVersion(int version) =>
      'Ce thème vient d’une version plus récente de Niman (version $version)';
  @override
  String themeImportBadRole(String role) =>
      'Le fichier ne donne pas de couleur pour « $role »';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'Taille du texte de l’interface';
  @override
  String get uiTextScaleSubtitle =>
      'L’arborescence, les onglets et les dialogues ; en plus du réglage '
      'du système';
  @override
  String get noteTextScaleTitle => 'Taille du texte des notes';
  @override
  String get noteTextScaleSubtitle =>
      'L’éditeur et l’aperçu, qui restent d’accord';

  // Settings: preview mode.
  @override
  String get previewModeTitle => 'Mode aperçu';
  @override
  String get previewModeSubtitle =>
      'Si l’aperçu partage l’écran avec l’éditeur ou le remplace';
  @override
  String get previewModeAuto => 'Côte à côte';
  @override
  String get previewModeSwitch => 'Plein écran';
  @override
  String get splitRatioTitle => 'Largeur de la division';
  @override
  String get splitRatioSubtitle =>
      'La part de l’éditeur quand l’aperçu est côte à côte';

  // Settings: editor formatting.
  @override
  String get linkTypeTitle => 'Format du lien';
  @override
  String get linkTypeSubtitle => 'Ce que le bouton lien de l’éditeur insère';
  @override
  String get linkTypeWikilink => 'Wikilink';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get missingNoteLocationTitle => 'Créer les notes manquantes dans';
  @override
  String get missingNoteLocationRoot => 'Racine de la bibliothèque';
  @override
  String get missingNoteLocationCurrentFolder => 'Dossier actuel';
  @override
  String get indentWidthTitle => 'Largeur d’indentation';
  @override
  String get indentWidthSubtitle =>
      'Espaces ajoutés à chaque niveau d’indentation dans l’éditeur';

  // Settings: language (T-L10N-04).
  @override
  String get languageTitle => 'Langue';
  @override
  String get languageSubtitle => 'La langue des textes de l’app';
  @override
  String get languageSystem => 'Système';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Ajouter un élément';
  @override
  String get listAddTooltip => 'Ajouter un élément';
  @override
  String get listEmpty => 'Aucun élément pour l’instant';
  @override
  String get listDragHandleLabel => 'Réorganiser l’élément';

  // Audio note kind (issue #56).
  @override
  String get audioEmpty => 'Aucun enregistrement pour l’instant';
  @override
  String get audioRecord => 'Enregistrer';
  @override
  String get audioStop => 'Arrêter';
  @override
  String get audioPlay => 'Lire';
  @override
  String get audioDelete => 'Supprimer l’enregistrement';
  @override
  String get audioImport => 'Importer un fichier audio';
  @override
  String get audioRecording => 'Enregistrement…';
  @override
  String get audioPermissionDenied =>
      'Accès au microphone refusé — il est nécessaire pour enregistrer.';
  @override
  String get newAudioNoteTitle => 'Nouvelle note vocale';
  @override
  String get newAudioNoteDefault => 'Mon enregistrement';
  @override
  String get showAudioTooltip => 'Afficher les enregistrements';
  @override
  String get audioMessageHint => 'Écrire une note…';
  @override
  String get audioSend => 'Envoyer';
  @override
  String get audioRename => 'Renommer l’enregistrement';
  @override
  String get audioDescriptionHint => 'Décrire cet enregistrement…';
  @override
  String get audioEditDescription => 'Modifier la description';
  @override
  String get audioDeleteNote => 'Supprimer la note';
  @override
  String get audioEditNote => 'Modifier la note';
  @override
  String get audioPause => 'Pause';
  @override
  String get audioEditTitle => 'Modifier le titre';
  @override
  String get audioTitleHint => 'Titre de cet enregistrement…';
  @override
  String audioUntitled(int n) => 'Enregistrement $n';
  @override
  String get audioMoreActions => "Plus d'actions";
  @override
  String get audioDiscardRecording => "Abandonner l'enregistrement";
  @override
  String get audioPauseRecording => 'Mettre l’enregistrement en pause';
  @override
  String get audioResumeRecording => 'Reprendre l’enregistrement';
  @override
  String get audioRecordingPaused => 'En pause';
  @override
  String get audioSavingRecording => 'Enregistrement du fichier…';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Note rapide';
  @override
  String get trayOpen => 'Ouvrir Niman';
  @override
  String get trayQuit => 'Quitter';
  @override
  String get closeToTrayTitle => 'Fermer dans la zone de notification';
  @override
  String get closeToTraySubtitle =>
      'Le × de la fenêtre masque Niman et le laisse tourner, pour que les '
      'rappels arrivent encore. On quitte depuis le menu de l’icône.';
  @override
  String get shortcutNewTodo => 'Nouvelle tâche';
  @override
  String get shortcutNewNote => 'Nouvelle note';
  @override
  String get shortcutNewList => 'Nouvelle liste';
  @override
  String get shortcutNewAudio => 'Nouvelle note vocale';
  @override
  String get shortcutToggleSidebar =>
      'Afficher ou masquer l’arborescence des fichiers';
  @override
  String get shortcutCloseTab => 'Fermer la note actuelle';
  @override
  String get shortcutNextTab => 'Note ouverte suivante';
  @override
  String get shortcutPreviousTab => 'Note ouverte précédente';
  @override
  String get shortcutEditorSection => 'Dans l’éditeur';
  @override
  String get shortcutFormatSection => 'Mise en forme';
  @override
  String get shortcutFind => 'Rechercher';
  @override
  String get shortcutReplace => 'Rechercher et remplacer';
  @override
  String get shortcutSavingNote =>
      'Les modifications sont enregistrées automatiquement : il n’y a pas '
      'de raccourci d’enregistrement.';

  // Editor status bar.
  @override
  String get noteStatusLoading => 'Chargement…';
  @override
  String get noteStatusSaving => 'Enregistrement…';
  @override
  String get noteStatusUnsaved => 'Non enregistré';
  @override
  String get noteStatusSaved => 'Enregistré';
  @override
  String get noteStatusError => 'Erreur';
  @override
  String get noteNotText =>
      'Ce fichier n’est pas une note texte, Niman '
      'ne peut donc pas l’afficher ici.';
  @override
  String get noteLoadFailed => 'Impossible d’ouvrir cette note.';
  @override
  String wordCount(int count) => count == 1 ? '1 mot' : '$count mots';
  @override
  String get outlineTooltip => 'Plan';
  @override
  String get outlineNoHeadings => 'Aucun titre';
  @override
  String get outlineNoTitle => '(sans titre)';

  // Editor toolbar: one name per button.
  @override
  String get toolbarBold => 'Gras';
  @override
  String get toolbarItalic => 'Italique';
  @override
  String get toolbarStrikethrough => 'Barré';
  @override
  String get toolbarSuperscript => 'Exposant';
  @override
  String get toolbarUnderline => 'Souligné';
  @override
  String get toolbarLink => 'Lien';
  @override
  String get toolbarCode => 'Bloc de code';
  @override
  String get toolbarImage => 'Insérer une image';
  @override
  String get toolbarHeading => 'Titre';
  @override
  String get toolbarList => 'Liste';
  @override
  String get toolbarOrderedList => 'Liste numérotée';
  @override
  String get toolbarQuote => 'Citation';
  @override
  String get toolbarIndent => 'Augmenter l’indentation';
  @override
  String get toolbarOutdent => 'Réduire l’indentation';

  // Editor tools (#136): the Tools button, the sheet it opens, and
  // the list count that is the first tool in it.
  @override
  String get toolbarTools => 'Outils';
  @override
  String get editorToolsTitle => "Outils de l'éditeur";
  @override
  String get toolCountListTitle => 'Compter une liste';
  @override
  String get toolCountListSubtitle =>
      'Additionne ce que les lignes énumèrent, en liste à cocher';
  @override
  String get toolCountListNeedsList => "Cette note n'a aucune liste à compter";
  @override
  String get tallySourceLabel => 'Liste';
  @override
  String get tallyCutLabel => 'Lire chaque ligne comme';
  @override
  String get tallyCutDash => 'Nom - valeurs';
  @override
  String get tallyCutColon => 'Nom : valeurs';
  @override
  String get tallyCutCommas => 'Valeurs séparées par des virgules';
  @override
  String get tallyCutWhole => 'Toute la ligne, comme une seule valeur';
  @override
  String get tallySortLabel => 'Ordre';
  @override
  String get tallySortCount => "Les plus nombreux d'abord";
  @override
  String get tallySortAlphabetical => 'Alphabétique';
  @override
  String get tallySortFirstSeen => "Dans l'ordre de la liste";
  @override
  String get tallyInsert => 'Insérer';
  @override
  String get tallyUpdate => 'Mettre à jour';
  @override
  String get tallyNothingToCount => 'Rien à compter ici';
  @override
  String get headingDialogTitle => 'Niveau du titre';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => 'Barre d’outils de l’éditeur';
  @override
  String get toolbarSettingsHint =>
      'Glissez pour réorganiser ; l’œil affiche ou masque un bouton.';
  @override
  String get toolbarShowButton => 'Afficher';
  @override
  String get toolbarHideButton => 'Masquer';
  @override
  String get toolbarResetOrder => 'Restaurer les valeurs par défaut';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => 'Afficher l’aperçu';
  @override
  String get showEditorTooltip => 'Afficher l’éditeur';
  @override
  String get enterFullScreenTooltip => 'Plein écran';
  @override
  String get exitFullScreenTooltip => 'Quitter le plein écran';

  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '(tableau HTML brut)';

  // Search (T-M3-05).
  @override
  String get searchHint => 'Rechercher dans les notes';
  @override
  String get searchModeWords => 'Mots';
  @override
  String get searchModeContains => 'Contient';
  @override
  String get searchEmptyHint =>
      'Saisissez pour chercher dans la bibliothèque, ou clé = valeur pour '
      'filtrer par frontmatter';
  @override
  String get searchTooShortHint => 'Saisissez au moins 2 caractères';
  @override
  String get searchNoMatches => 'Aucun résultat';
  @override
  String get searchLoadMore => 'Afficher plus';

  // Replace (T-M3-10).
  @override
  String get replaceTooltip => 'Remplacer…';
  @override
  String get replaceInNoteAction => 'Remplacer dans cette note…';
  @override
  String get replaceInThisNote => 'Remplacer dans cette note';
  @override
  String get replaceWithLabel => 'Remplacer par';
  @override
  String get replaceCaseSensitive => 'Respecter la casse';
  @override
  String get replaceWholeWordsHint =>
      'seuls les mots entiers exacts sont remplacés';
  @override
  String get replaceConfirm => 'Remplacer';
  @override
  String get replaceCancel => 'Fermer';
  @override
  String get replaceUnavailable =>
      'Le remplacement n’est pas disponible pour l’instant';

  // Editor find & replace.
  @override
  String get findInNoteTooltip => 'Rechercher dans la note';
  @override
  String get editorFindHint => 'Rechercher';
  @override
  String get editorReplaceHint => 'Remplacer';
  @override
  String get editorFindCaseTooltip => 'Respecter la casse';
  @override
  String get editorFindPreviousTooltip => 'Correspondance précédente';
  @override
  String get editorFindNextTooltip => 'Correspondance suivante';
  @override
  String get editorFindCloseTooltip => 'Fermer la recherche';
  @override
  String get editorFindReplaceModeTooltip => 'Mode remplacement';
  @override
  String get editorReplaceOneTooltip => 'Remplacer cette correspondance';
  @override
  String get editorReplaceAllTooltip => 'Remplacer toutes';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => 'Étiquettes';
  @override
  String get tagsTitle => 'Étiquettes';
  @override
  String get tagsEmpty =>
      'Aucune étiquette pour l’instant — ajoutez un #tag ou des '
      'étiquettes dans le frontmatter';
  @override
  String get tagsBackTooltip => 'Retour à la recherche';
  @override
  String get tagsNotesEmpty => 'Aucune note avec cette étiquette';
  @override
  String tagsNotesCapped(int limit) =>
      'Seules les $limit premières sont listées — recherchez l’étiquette '
      'pour restreindre';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => 'Lien introuvable';
  @override
  String get headingNotFoundTitle => 'Titre introuvable';
  @override
  String get ambiguousLinkTitle => 'Plusieurs notes correspondent';
  @override
  String get openLinkFailed => 'Impossible d’ouvrir le lien';

  // Dead-link note creation (issue #78).
  @override
  String get missingNoteDialogTitle => 'La note n’existe pas';
  @override
  String missingNoteDialogBody(String path) => 'Créer « $path » ?';
  @override
  String missingNoteFolderMissing(String folder) =>
      'Le dossier « $folder » n’existe pas';

  // Task lists (T-TD-04).
  @override
  String get todoOpen => 'À faire';
  @override
  String get todoDone => 'Faites';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => 'Toutes les dates';
  @override
  String get todoFilter => 'Filtrer';
  @override
  String get todoNoTokens => 'Aucun jeton dans cette liste';
  @override
  String get todoCountOpen => 'à faire';
  @override
  String get todoCountDone => 'faites';
  @override
  String get todoEmptyOpen => 'Aucune tâche à faire pour l’instant';
  @override
  String get todoEmptyDone => 'Rien de terminé pour l’instant';
  @override
  String get todoEmptyFiltered => 'Aucune tâche ne correspond';
  @override
  String get todoTitle => 'Tâches';
  @override
  String get todoAddTooltip => 'Ajouter une tâche';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'Le format todo.txt';
  @override
  String get todoHelpTooltip => 'Aide sur le format';
  @override
  String get todoHelpIntro =>
      'Vos tâches sont un simple fichier texte, une tâche par ligne. '
      'Niman écrit la syntaxe pour vous, mais rien n’est caché : vous '
      'pouvez modifier le fichier dans n’importe quel éditeur et Niman '
      'le relira.';
  @override
  String get todoHelpFilesTitle => 'Les deux fichiers';
  @override
  String get todoHelpFilesBody =>
      'Les tâches à faire sont dans todo.txt à la racine de votre '
      'bibliothèque. En terminant une tâche, sa ligne passe dans '
      'done.txt, pour que todo.txt reste court. Si une ligne terminée '
      'retrouve sa place dans todo.txt, Niman l’archive à la prochaine '
      'lecture des fichiers.';
  @override
  String get todoHelpLineTitle => 'Anatomie d’une ligne';
  @override
  String get todoHelpLineBody =>
      'Tout ce qui précède la description est facultatif et doit '
      'apparaître dans cet ordre :';
  @override
  String get todoHelpDoneBody =>
      'Marque la tâche comme faite. Niman l’ajoute quand vous cochez la '
      'case.';
  @override
  String get todoHelpPriority => 'de (A) à (Z)';
  @override
  String get todoHelpPriorityBody =>
      'Priorité. A est la plus haute. Affichée en badge dans la liste.';
  @override
  String get todoHelpDatesBody =>
      'Date de complétion, puis date de création. Avec une seule date, '
      'c’est la date de création, sauf si la ligne commence par x.';
  @override
  String get todoHelpTokensTitle => 'Projets, contextes et étiquettes';
  @override
  String get todoHelpTokensBody =>
      'Partout dans la description, un mot avec l’un de ces préfixes '
      'devient une pastille sur laquelle filtrer. Rien n’est prédéfini : '
      'un jeton existe dès que vous l’écrivez.';
  @override
  String get todoHelpProjectBody =>
      'De quoi la tâche fait partie, par exemple +cuisine ou +thèse.';
  @override
  String get todoHelpContextBody =>
      'Où ou comment vous la ferez, par exemple @domicile ou @appels.';
  @override
  String get todoHelpHashtagBody =>
      'Une étiquette libre, pour tout ce que les deux autres ne '
      'couvrent pas.';
  @override
  String get todoHelpTagsTitle => 'Dates et rappels';
  @override
  String get todoHelpTagsBody =>
      'Ce sont des étiquettes clé:valeur. Niman les écrit depuis la '
      'fenêtre de la tâche et les lit où qu’elles apparaissent dans la '
      'ligne.';
  @override
  String get todoHelpDueBody =>
      'La date d’échéance. Elle conduit le badge coloré et les filtres '
      'par date.';
  @override
  String get todoHelpRemBody =>
      'Quand envoyer une notification, dans votre heure locale. Elle se '
      'déclenche écran éteint et application fermée.';
  @override
  String get todoHelpRemDesktop =>
      'Sur bureau, Niman doit être en marche quand l’heure arrive : le '
      'rappel s’affiche pendant que l’app est ouverte, et rien ne se '
      'déclenche quand elle est fermée.';
  @override
  String get todoHelpOtherBody =>
      'Conservées exactement comme écrites, pour que les étiquettes '
      'd’autres applications todo.txt survivent au voyage. Niman ne '
      'les interprète pas, rec: compris : une tâche récurrente n’est '
      'pas encore répétée.';
  @override
  String get todoHelpEditTitle => 'Édition hors de Niman';
  @override
  String get todoHelpEditBody =>
      'Une tâche que vous n’avez pas touchée est réécrite byte pour '
      'byte, espacements étranges compris. Modifiez une ligne et Niman '
      'réécrit cette ligne en forme canonique, en laissant le reste du '
      'fichier tranquille.';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => 'Ajouter une tâche';
  @override
  String get todoEditTitle => 'Modifier la tâche';
  @override
  String get todoDescriptionHint => 'Description';
  @override
  String get todoCancel => 'Annuler';
  @override
  String get todoSave => 'Enregistrer';
  @override
  String get todoEditAction => 'Modifier';
  @override
  String get todoDeleteAction => 'Supprimer';

  // Task filters (T-TD-05).
  @override
  String get todoDueOverdue => 'En retard';
  @override
  String get todoDueToday => 'Aujourd’hui';
  @override
  String get todoDueNext7 => '7 prochains jours';
  @override
  String get todoDueNoDate => 'Sans date';
  @override
  String get todoRowDue => 'Échéance';
  @override
  String get todoRowDueToday => 'Échéance aujourd’hui';
  @override
  String get todoSortTooltip => 'Trier';
  @override
  String get todoSortDue => 'Date d’échéance';
  @override
  String get todoSortPriority => 'Priorité';
  @override
  String get todoSortCreation => 'Date de création';

  // Task dialog pickers (T-TD-06).
  @override
  String get todoNoPriority => 'Sans priorité';
  @override
  String get todoNoPriorityShort => 'Aucune';
  @override
  String get todoMorePriorities => 'Plus…';
  @override
  String get todoPriorityTitle => 'Priorité';
  @override
  String get todoNoDueDate => 'Sans date d’échéance';
  @override
  String get todoNoReminder => 'Sans rappel';
  @override
  String get todoAddProject => '+ Projet';
  @override
  String get todoAddContext => '@ Contexte';
  @override
  String get todoAddHashtag => '# Étiquette';

  // Task reminders (T-TD-07).
  @override
  String get todoReminderChannel => 'Rappels de tâches';
  @override
  String get todoReminderChannelDescription =>
      'Alertes planifiées pour les tâches avec un horaire de rappel.';
  @override
  String get todoReminderBody => 'Rappel de tâche';
  @override
  String get todoReminderFallbackTitle => 'Rappel de tâche';
  @override
  String get todoReminderBlocked =>
      'Les notifications sont désactivées, les rappels ne s’afficheront '
      'pas.';
  @override
  String get todoReminderBattery =>
      'L’optimisation de la batterie est activée pour Niman. Le système '
      'peut mettre l’app en veille et perdre les rappels en attente.';
  @override
  String get todoReminderInexact =>
      'Cet appareil n’autorise pas les alarmes exactes : un rappel peut '
      'arriver avec quelques minutes de retard, écran éteint.';
  @override
  String get reminderShowTokensTitle =>
      'Étiquettes dans les notifications de rappel';
  @override
  String get reminderShowTokensSubtitle =>
      'Conserve +projet, @contexte et #tag dans le texte de la '
      'notification. Off n’affiche que la tâche que vous avez saisie.';
  @override
  String get todoReminderFixAction => 'Ouvrir les paramètres';
  @override
  String get todoReminderDismissAction => 'Ignorer';
  @override
  String get todoReminderDue => 'Échéance';

  // Actions and buttons shared by the dialogs (T-L10N-06).
  @override
  String get actionOk => 'OK';
  @override
  String get actionCancel => 'Annuler';
  @override
  String get actionCreate => 'Créer';
  @override
  String get actionNew => 'Nouveau';
  @override
  String get actionSave => 'Enregistrer';
  @override
  String get actionClear => 'Vider';
  @override
  String get actionChoose => 'Choisir';
  @override
  String get actionDelete => 'Supprimer';
  @override
  String get actionRename => 'Renommer';
  @override
  String get actionMove => 'Déplacer';
  @override
  String get saveAndClose => 'Enregistrer et fermer';
  @override
  String get closeUnsavedTitle => 'Modifications non enregistrées';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return '« ${names.first} » contient des modifications non '
          'enregistrées. Les enregistrer avant de fermer ?';
    }
    return '$names.length notes contiennent des modifications non '
        'enregistrées. Les enregistrer avant de fermer ?';
  }

  @override
  String get closeSaveFailed =>
      'Enregistrement impossible ; la note reste ouverte.';
  @override
  String get actionRestore => 'Restaurer';
  @override
  String get actionEmpty => 'Vider';

  // The shell: app bar, tabs and tree actions.
  @override
  String get hideSidebarTooltip => 'Masquer le panneau (Ctrl+B)';
  @override
  String get showSidebarTooltip => 'Afficher le panneau (Ctrl+B)';
  @override
  String get windowMinimizeTooltip => 'Réduire';
  @override
  String get windowMaximizeTooltip => 'Agrandir';
  @override
  String get windowRestoreTooltip => 'Restaurer';
  @override
  String get windowCloseTooltip => 'Fermer';
  @override
  String get tabFiles => 'Fichiers';
  @override
  String get tabSearch => 'Recherche';
  @override
  String get tabSettings => 'Paramètres';
  @override
  String get quickNoteTitle => 'Note rapide';
  @override
  String get treeEmpty => 'Aucune note pour l’instant';
  @override
  String get selectANote => 'Sélectionnez une note';
  @override
  String get showListTooltip => 'Afficher la liste';
  @override
  String get editRawTooltip => 'Modifier le texte brut';
  @override
  String get sortAscTooltip => 'Trier A-Z';
  @override
  String get sortDescTooltip => 'Trier Z-A';
  @override
  String get newNoteTitle => 'Nouvelle note';
  @override
  String get newItemTooltip => 'Nouveau';
  @override
  String get closeMenuTooltip => 'Fermer';
  @override
  String get newFolderTitle => 'Nouveau dossier';
  @override
  String get newNoteSameFolder => 'Nouvelle note dans le même dossier';
  @override
  String get newFromTemplateSameFolder =>
      'Nouvelle depuis un modèle dans le même dossier';
  @override
  String trashOriginalPath(String path) => 'était dans $path';
  @override
  String get trashOriginalRoot =>
      '\u00e9tait \u00e0 la racine de la biblioth\u00e8que';
  @override
  String trashItemCount(int count) =>
      count == 1 ? '1 \u00e9l\u00e9ment' : '$count \u00e9l\u00e9ments';
  @override
  String get newNoteHere => 'Nouvelle note ici';
  @override
  String get newFolderHere => 'Nouveau dossier ici';
  @override
  String get newListNoteTitle => 'Nouvelle note-liste';
  @override
  String get newListNoteDefault => 'Ma liste';
  @override
  String get setAsQuickNote => 'Définir comme note rapide';
  @override
  String get currentQuickNote => 'Note rapide actuelle';
  @override
  String get pinnedSection => 'Épinglées';
  @override
  String pinnedSectionCount(int count) => 'Épinglées · $count';
  @override
  String get templateFolderTitle => 'Dossier des modèles';
  @override
  String get newFromTemplateTitle => 'Nouveau depuis un modèle';
  @override
  String get newFromTemplateHere => 'Nouveau depuis un modèle ici';
  @override
  String get templateFormTitle => 'Remplir le modèle';
  @override
  String get templateFormBacklink => 'Liée depuis';
  @override
  String get templateFormNoNote => 'Aucune note';
  @override
  String get templateFormPickNote => 'Choisir la note';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => 'Emplacements réservés des modèles';
  @override
  String get templateHelpSubtitle =>
      'Date, titre et les autres valeurs à renseigner';
  @override
  String get quickNoteSubtitle => 'La note qu’ouvre l’onglet Note rapide';
  @override
  String get listFolderSubtitle => 'Les nouvelles listes de tâches';
  @override
  String get templateFolderSubtitle =>
      'La source de « Nouveau depuis un modèle »';
  @override
  String get attachmentsFolderSubtitle =>
      'Images et audio insérés dans une note';
  @override
  String get templateHelpIntro =>
      'Un modèle est une note ordinaire avec des trous. Créer une note '
      'depuis un modèle copie son texte et remplit les trous.';
  @override
  String get templateHelpUnknown =>
      'Un emplacement réservé que Niman ne connaît pas reste tel quel, '
      'pour qu’une coquille se voie dans la note au lieu de faire '
      'disparaître une ligne en silence.';
  @override
  String get templateHelpValuesTitle => 'Valeurs';
  @override
  String get templateHelpTitleBody =>
      'Le nom sous lequel la note va être créée.';
  @override
  String get templateHelpDateBody =>
      'Aujourd’hui, et l’heure maintenant. Les deux prennent un format : '
      '{{date:DD/MM/YYYY}}.';
  @override
  String get templateHelpNowBody => 'La date et l’heure ensemble.';
  @override
  String get templateHelpUuidBody =>
      'Un identifiant neuf, différent à chaque occurrence.';
  @override
  String get templateHelpCounterBody =>
      'Un nombre qui compte par nom, conservé entre les redémarrages : '
      'la première note écrit 1, la suivante 2. Le même nom dans une '
      'note écrit le même nombre ; à combiner avec |pad:3.';
  @override
  String get templateHelpCursorBody =>
      'Place le curseur ici quand la note est créée ; le marqueur '
      'lui-même n’est pas écrit. Le premier marqueur l’emporte, pas de '
      'filtres, notes neuves seulement — et le clavier s’ouvre même '
      'avec l’auto-focus désactivé.';
  @override
  String get templateHelpDatesTitle => 'Écrire une date';
  @override
  String get templateHelpDatesBody =>
      'Ceux-ci désignent des parties de la date dans un format. Tout le '
      'reste est littéral, et aussi le texte entre guillemets simples. '
      'Les noms de mois et de jour suivent la langue de l’app.';
  @override
  String get templateHelpYear => 'l’année : 2026, 26';
  @override
  String get templateHelpMonth => 'le mois : 03, 3, mars, mars';
  @override
  String get templateHelpDay => 'le jour : 09, 9, lundi, lun.';
  @override
  String get templateHelpTime => 'heures, minutes, secondes';
  @override
  String get templateHelpWeek => 'la semaine ISO et le trimestre : 11, 11, 1';
  @override
  String get templateHelpFiltersTitle => 'Filtres';
  @override
  String get templateHelpFiltersBody =>
      'Une valeur peut être suivie de filtres, appliqués de gauche à '
      'droite.';
  @override
  String get templateHelpCaseBody =>
      'Majuscules, minuscules, et la première lettre de chaque mot — un '
      'mot que vous avez capitalisé vous-même est laissé tel quel.';
  @override
  String get templateHelpSlugBody =>
      'La forme lien du texte, pour construire un wikilink.';
  @override
  String get templateHelpPadBody =>
      'Supprime les espaces aux extrémités ; remplit de zéros jusqu’à une '
      'largeur ; utilise un repli quand la valeur est vide.';
  @override
  String get templateHelpShiftBody =>
      'Décale une date de jours, semaines, mois ou années — le cours de '
      'la semaine prochaine, le fichier du mois dernier.';
  @override
  String get templateHelpSnapBody =>
      'Aligne une date sur le début ou la fin de sa semaine, de son mois '
      'ou de son année.';
  @override
  String get templateHelpAskTitle => 'Vous demander quelque chose';
  @override
  String get templateHelpAskBody =>
      'Un formulaire apparaît avant que la note soit créée, une case par '
      'question — et une pour le lien retour, quand le modèle en veut '
      'un. La même étiquette deux fois est une seule question, et sa '
      'réponse remplit chaque occurrence — le dossier et le nom du '
      'fichier compris.';
  @override
  String get templateHelpAskFieldBody =>
      'Une case à remplir ; le texte après les deux-points doubles est '
      'celui avec lequel elle part.';
  @override
  String get templateHelpChoiceBody =>
      'Un choix dans une liste, séparé par des virgules.';
  @override
  String get templateHelpWhereTitle => 'Où va la note';
  @override
  String get templateHelpWhereBody =>
      'Ce ne sont pas du texte : ce sont des instructions, et elles '
      'vivent dans un bloc niman: du frontmatter du modèle lui-même. Le '
      'bloc est exécuté puis retiré, il n’apparaît donc jamais dans la '
      'note. Leurs valeurs peuvent contenir des emplacements réservés.';
  @override
  String get templateHelpFolderBody =>
      'Le dossier dans lequel la note est créée, créé s’il n’existe pas. '
      'Sans lui, la note arrive là où vous étiez.';
  @override
  String get templateHelpFilenameBody =>
      'Ce que la note s’appelle. Un modèle qui le déclare n’est pas '
      'interrogé sur le nom.';
  @override
  String get templateHelpAppendBody =>
      'Ajoute à la note si elle existe déjà, au lieu d’en créer une '
      'seconde. C’est ce qui transforme un mois de réunions en un seul '
      'fichier.';
  @override
  String get templateHelpOpenBody =>
      'Ce qui se passe quand la note existe : l’éditeur (la valeur par '
      'défaut), l’aperçu, ou rien — la note est classée et vous restez '
      'là où vous étiez.';
  @override
  String get templateHelpAroundTitle => 'D’où elle vient';
  @override
  String get templateHelpParentBody =>
      'Une note que vous choisissez dans le formulaire, qui propose '
      'celle à l’écran ; écrivez [[{{parent}}]] pour un lien retour.';
  @override
  String get templateHelpFolderValueBody =>
      'Le dossier dans lequel la note a atterri.';
  @override
  String get templateHelpClipboardBody =>
      'Ce qui est dans le presse-papiers, et la sélection de l’éditeur '
      'quand la note est partie d’une sélection.';
  @override
  String get templateHelpIncludeTitle => 'Réutiliser un morceau';
  @override
  String get templateHelpIncludeBody =>
      'Colle un autre modèle, pour que dix modèles partagent une seule '
      'checklist. Il est cherché d’abord dans le dossier des modèles, et '
      'le .md peut être omis. Ses propres questions rejoignent le même '
      'formulaire.';
  @override
  String get templateHelpExampleTitle => 'Tout ensemble';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ aucun modèle « $path »';
  @override
  String includeCycle(String path) => '⚠ « $path » s’inclut lui-même';
  @override
  String includeTooDeep(String path) =>
      '⚠ « $path » est imbriqué trop profondément';
  @override
  String frontmatterInvalid(String reason) => 'Frontmatter non lu : $reason';
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      'Le frontmatter de « $template » n’a pas été lu, son dossier et son '
      'nom de fichier n’ont donc rien fait : $reason';
  @override
  String get templatePickerTitle => 'Choisir un modèle';
  @override
  String templatePickerEmpty(String folder) =>
      'Aucun modèle pour l’instant. Mettez une note dans $folder/ et elle '
      'devient un modèle.';

  // Tree actions.
  @override
  String get actionPin => 'Épingler';
  @override
  String get actionUnpin => 'Désépingler';
  @override
  String get pinToWidget => 'Épingler dans le widget d’accueil';
  @override
  String get pinnedForWidget =>
      'Épinglé : placez maintenant le widget Note sur l’écran d’accueil';
  @override
  String get pinWidgetUnavailable =>
      'Les widgets de l’écran d’accueil sont disponibles sur Android';

  // Handing a note's file to the OS (issue #76).
  @override
  String get openInFileManager => 'Afficher dans le gestionnaire de fichiers';
  @override
  String get openInDefaultApp => 'Ouvrir avec l’application par défaut';
  @override
  String get newNoteTabTooltip => 'Nouvelle note dans un nouvel onglet';
  @override
  String get openNotesTooltip => 'Notes ouvertes';
  @override
  String get closeTabTooltip => 'Fermer';
  @override
  String get openInNewTab => 'Ouvrir dans un nouvel onglet';
  @override
  String get splitRight => 'Diviser à droite';
  @override
  String get splitDown => 'Diviser en bas';
  @override
  String get moveToOtherPane => 'Déplacer dans l’autre volet';
  @override
  String get openBeside => 'Ouvrir à côté';
  @override
  String get closeAllNotes => 'Tout fermer';
  @override
  String get sidePanelTooltip => 'Afficher ou masquer le panneau latéral';
  @override
  String get historyAllVersions => 'Toutes les versions';
  @override
  String get commandPaletteTitle => 'Palette de commandes';
  @override
  String get goToNoteTitle => 'Aller à la note';
  @override
  String get paletteGroupNote => 'Note';
  @override
  String get paletteGroupEditor => 'Éditeur';
  @override
  String get paletteGroupView => 'Affichage';
  @override
  String get paletteGroupLibrary => 'Bibliothèque';
  @override
  String get paletteGroupGoTo => 'Aller à';
  @override
  String get commandsTitle => 'Commandes';
  @override
  String get commandsIntro =>
      'La palette de commandes ne propose que les commandes exécutables là où '
      'vous êtes. Les voici toutes, avec le moment où chacune apparaît.';
  @override
  String get commandNeedNone => 'Toujours disponible';
  @override
  String get commandNeedOpenNote => 'Nécessite une note ouverte';
  @override
  String get commandNeedWideWindow => 'Fenêtre large uniquement';
  @override
  String get commandNeedDockRoom =>
      'Nécessite une fenêtre assez large pour le panneau latéral';
  @override
  String get commandNeedDesktop => 'Bureau uniquement';
  @override
  String get commandNeedNotInZen => 'Pas en mode Zen';
  @override
  String get commandNeedZenRoom =>
      'Bureau, avec une note ouverte dans un onglet';
  @override
  String get commandNeedPreview => "Avec l'aperçu activé, sur une note texte";
  @override
  String get commandNeedTwoEditors => 'Avec les deux éditeurs activés';
  @override
  String get paletteHint => 'Chercher des commandes et des notes';
  @override
  String get paletteNoResults => 'Aucun résultat';
  @override
  String get paletteCommands => 'Commandes';
  @override
  String get paletteNotes => 'Notes';
  @override
  String get paletteFooter =>
      '↑↓ pour naviguer · ↵ pour utiliser · échap pour fermer';
  @override
  String get paletteFooterTouch =>
      'Touchez pour exécuter · l’épingle le garde en haut';
  @override
  String get palettePinned => 'Épinglés';
  @override
  String get palettePin => 'Épingler';
  @override
  String get paletteUnpin => 'Détacher';
  @override
  String get palettePinFooter => 'alt+P pour épingler';
  @override
  String get spellCheckScanning => 'Vérification de la note…';
  @override
  String get spellCheckAgain => 'Vérifier à nouveau';
  @override
  String spellCheckCapped(int count) =>
      'Les $count premiers sont listés : corrigez-en quelques-uns, puis '
      'vérifiez à nouveau pour le reste';
  @override
  String get dropHint =>
      'Déposez des fichiers Markdown pour les ouvrir, ou un dossier pour '
      'l’importer';
  @override
  String get dropNothing =>
      'Le bureau n’a transmis aucun fichier pour ce dépôt.';
  @override
  String get importFolderAction => 'Importer';
  @override
  String dropRejected(String names) =>
      'Seuls les fichiers Markdown et les dossiers s’ouvrent ici : $names';
  @override
  String importFolderTitle(String name) => 'Importer « $name » ?';
  @override
  String importFolderBody(int count) =>
      'Ses fichiers Markdown ($count) sont copiés dans un nouveau dossier de '
      'la bibliothèque. Le dossier déposé reste tel quel.';
  @override
  String importFolderDone(String folder) => 'Importé dans $folder';
  @override
  String importFolderEmpty(String name) => 'Aucun fichier Markdown dans $name';
  @override
  String get openFileTitle => 'Ouvrir un fichier';
  @override
  String get outsideFileNote =>
      'Hors de toute bibliothèque : enregistré sur place, non indexé, sans '
      'historique, liens non suivis';
  @override
  String get typewriterOn => 'Activer le mode machine à écrire';
  @override
  String get typewriterOff => 'Désactiver le mode machine à écrire';
  @override
  String get typewriterTitle => 'Mode machine à écrire';
  @override
  String get formatNoteTitle => 'Ranger le Markdown';
  @override
  String get formatNoteDone => 'La note a été rangée.';
  @override
  String get formatNoteAlreadyTidy => 'La note était déjà rangée.';
  @override
  String get typewriterSubtitle =>
      'Garder la ligne en cours d’écriture au milieu de l’éditeur';
  @override
  String get zenMode => 'Mode zen';
  @override
  String get zenModeEnter => 'Passer en mode zen';
  @override
  String get zenModeLeave => 'Quitter le mode zen';
  @override
  String get keySpace => 'Espace';
  @override
  String get keyEnter => 'Entrée';
  @override
  String get keyTab => 'Tab';
  @override
  String get keyEscape => 'Échap';
  @override
  String get keyBackspace => 'Retour arrière';
  @override
  String get keyDelete => 'Suppr';
  @override
  String get keyArrowUp => 'Haut';
  @override
  String get keyArrowDown => 'Bas';
  @override
  String get keyArrowLeft => 'Gauche';
  @override
  String get keyArrowRight => 'Droite';
  @override
  String get keyHome => 'Début';
  @override
  String get keyEnd => 'Fin';
  @override
  String get keyPageUp => 'Page préc.';
  @override
  String get keyPageDown => 'Page suiv.';
  @override
  String get keyInsert => 'Inser';
  @override
  String get shortcutNone => 'Aucun raccourci';
  @override
  String get shortcutRestoreDefaults => 'Rétablir les valeurs par défaut';
  @override
  String get shortcutRestoreDefaultsConfirm =>
      'Remettre tous les raccourcis comme Niman les livre ?';
  @override
  String get shortcutRevert => 'Revenir à la valeur par défaut';
  @override
  String get shortcutClear => 'Retirer le raccourci';
  @override
  String get shortcutCapturePrompt =>
      'Appuyez sur les touches. Échap et Tab sont capturées aussi : sortez '
      'avec Annuler.';
  @override
  String get shortcutCaptureNeedsModifier =>
      'Ajoutez Ctrl, Alt ou Méta : une touche seule sert à écrire.';
  @override
  String get shortcutMove => 'Le déplacer';
  @override
  String get shortcutUseAnyway => 'Utiliser quand même';
  @override
  String get shortcutUndo => 'Annuler la saisie';
  @override
  String get shortcutRedo => 'Rétablir';
  @override
  String get shortcutChange => 'Changer le raccourci';
  @override
  String shortcutCaptureTitle(String command) => 'Touches pour $command';
  @override
  String shortcutConflict(String keys, String other) =>
      '$keys appartient déjà à $other. Le déplacer ici ? $other n’aura plus '
      'de raccourci.';
  @override
  String shortcutTakesEditorKey(String keys, String what) =>
      '$keys est aussi $what dans les champs de texte et l’éditeur. Votre '
      'commande le prendra là aussi.';
  @override
  String get openFileMissing =>
      'Le fichier de cette note est introuvable sur le disque';
  @override
  String get openFileFailed =>
      'Impossible d’ouvrir cette note en dehors de Niman';

  @override
  String get movedToTrash => 'Mis à la corbeille';
  @override
  String get deletedMessage => 'Supprimé';
  @override
  String deleteToTrashConfirm(String name) => '$name sera déplacé dans .trash/';
  @override
  String deleteForeverConfirm(String name) =>
      '$name sera définitivement supprimé';
  @override
  String get chooseDestination => 'Choisir la destination';
  @override
  String get libraryRoot => 'Racine de la bibliothèque';
  @override
  String moveTitle(String name) => 'Déplacer $name';
  @override
  String headingLevelLabel(int level) => 'Titre niveau $level';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty =>
      'Aucune note rapide pour l’instant. Choisissez une note existante '
      'ou créez-en une nouvelle — la note rapide s’ouvre ici.';
  @override
  String get quickNoteChooseAction => 'Choisir une note…';
  @override
  String get quickNoteCreateAction => 'Créer une nouvelle note…';
  @override
  String get quickNoteNewTitle => 'Nouvelle note rapide';
  @override
  String get quickNotePickerTitle => 'Choisir la note rapide';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => 'Nouveau dossier';
  @override
  String get folderPickerEmpty => 'Aucun dossier pour l’instant';
  @override
  String get listFolderTitle => 'Dossier des listes';
  @override
  String get attachmentsFolderTitle => 'Dossier des pièces jointes';

  // Trash (M1).
  @override
  String get trashEmpty => 'La corbeille est vide';
  @override
  String get trashEmptyAction => 'Vider la corbeille';
  @override
  String get trashEmptyConfirm =>
      'Cela supprime définitivement tout le contenu du dossier corbeille, '
      'y compris les éléments que Niman n’y a pas mis.';
  @override
  String trashDeleteConfirm(String name) =>
      '$name sera définitivement supprimé (sans restauration)';
  @override
  String get trashDeletePermanently => 'Supprimer définitivement';

  // The open/create library screen.
  @override
  String get openLibraryIntro =>
      'Ouvrez un dossier de notes Markdown comme bibliothèque';
  @override
  String get openLibraryExisting => 'Ouvrir une existante';
  @override
  String get openLibraryCreate => 'Créer une nouvelle';
  @override
  String get openLibraryCreateTitle => 'Créer une nouvelle bibliothèque';
  @override
  String get openLibraryFolderName => 'Nom du dossier';
  @override
  String get openLibraryChooseFolder => 'Choisir le dossier de la bibliothèque';
  @override
  String get openLibraryChooseParent =>
      'Choisir le dossier dans lequel la bibliothèque sera créée';
  @override
  String get openLibraryUnsupported =>
      'Ce dossier n’est pas pris en charge. Choisissez un dossier du '
      'stockage de l’appareil.';
  @override
  String indexingCount(int done, int total) => '$done notes sur $total';

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => 'Vos bibliothèques';
  @override
  String get libraryUnreachable => 'Inaccessible';
  @override
  String get libraryOpenedToday => 'Ouverte aujourd’hui';
  @override
  String get libraryOpenedYesterday => 'Ouverte hier';
  @override
  String libraryOpenedDaysAgo(int days) => 'Ouverte il y a $days jours';
  @override
  String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return 'Ouverte le $d/$m/${when.year}';
  }

  @override
  String get libraryOpenNow => 'Ouvrir maintenant';
  @override
  String get switchLibraryTitle => 'Changer de bibliothèque';
  @override
  String get libraryForget => 'Oublier';
  @override
  String libraryForgetTitle(String name) => 'Oublier « $name » ?';
  @override
  String get libraryForgetExplained =>
      'Elle quitte cette liste. Le dossier, les notes et les paramètres '
      'de la bibliothèque sont laissés tels quels, et la rouvrir la '
      'ramène.';

  // Android storage access.
  @override
  String get storageAccessAction => 'Accorder l’accès aux fichiers';
  @override
  String get storageAccessNeeded =>
      'Sans l’accès à tous les fichiers, Niman ne peut pas lire vos '
      'notes. Accordez-le pour ouvrir une bibliothèque.';
  @override
  String get storageAccessExplained =>
      'Niman lit vos notes comme des fichiers ordinaires, il faut donc '
      'que lui permette Android l’accès à tous les fichiers. Rien n’est '
      'téléversé, et seul le dossier de bibliothèque que vous '
      'choisissez est lu.';
  @override
  String folderAccessDenied(Object error) =>
      'Le système n’a pas donné accès au dossier : $error';
  @override
  String folderPickFailed(Object error) =>
      'Impossible de choisir un dossier : $error';

  // Settings screen rows and messages.
  @override
  String get settingsTitle => 'Paramètres';
  @override
  String get libraryPathTitle => 'Chemin de la bibliothèque';
  @override
  String get reindexTitle => 'Re-indexer maintenant';
  @override
  String get reindexDone => 'Ré-indexation terminée';
  @override
  String get closeLibraryTitle => 'Fermer la bibliothèque';
  @override
  String get exportLogTitle => 'Exporter le journal de débogage';
  @override
  String get exportLogSubtitle =>
      'Sauvegarde les événements enregistrés dans un fichier de votre '
      'choix';
  @override
  String get exportLogEmpty => 'Le tampon du journal de débogage est vide';
  @override
  String get quickNoteUnset => 'Pas encore définie';
  @override
  String exportLogDone(Object target) =>
      'Journal de débogage exporté vers $target';
  @override
  String exportLogFailed(Object error) => 'Échec de l’exportation : $error';

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) =>
      'Aucun mot entier « $term » n’a été trouvé';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      '$occurrences occurrence(s) de « $term » remplacée(s) dans $notes '
      'note(s)';
  @override
  String replaceSkipped(int skipped) =>
      ' ($skipped note(s) ouverte(s) ignorée(s))';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      'Aucun mot entier exact « $term » '
      '${only == null ? 'trouvé' : 'trouvé dans $only'}';

  // About (issue #80).
  @override
  String get settingsSectionAbout => 'À propos';
  @override
  String get versionTitle => 'Version';
  @override
  String get changelogTitle => 'Journal des modifications';
  @override
  String get changelogEmpty => 'Aucune entrée du journal disponible';
  @override
  String changelogWhatsNew(String version) =>
      'Nouveautés de la version $version';

  // Note history (issues #13, #55, #67).
  @override
  String get noteHistoryTitle => 'Historique';
  @override
  String get noteMenuTooltip => 'Actions sur la note';
  @override
  String get historyCurrentVersion => 'Version actuelle';
  @override
  String get historyCurrentSubtitle => 'La note telle qu’elle est maintenant';
  @override
  String get historyToday => 'Aujourd’hui';
  @override
  String get historyYesterday => 'Hier';
  @override
  String get historyReasonSession => 'avant modification';
  @override
  String get historyReasonInterval => 'pendant la modification';
  @override
  String get historyReasonRestore => 'avant restauration';
  @override
  String get historyReasonSync => 'avant synchronisation';
  @override
  String get historyReasonReplace => 'avant remplacement';
  @override
  String get historyReasonUnknown => 'récupérée';
  @override
  String get historySyncBase => 'base de synchronisation';
  @override
  String get historyEmpty =>
      'Aucune version pour l’instant. Niman en conserve une quand vous '
      'commencez à modifier la note, puis au plus une toutes les quelques '
      'minutes pendant que vous écrivez.';
  @override
  String historyKept(int kept, int limit) => kept < 2
      ? '$kept version conservée sur $limit'
      : '$kept versions conservées sur $limit';
  @override
  String get historyBaseKept =>
      'La base de synchronisation est conservée au-delà de la limite.';
  @override
  String get historyOff =>
      'L’historique est désactivé pour cette bibliothèque '
      '(Paramètres, Bibliothèque).';
  @override
  String get historyLoadFailed => 'Impossible de lire l’historique';
  @override
  String get historyCompareSubtitle => 'Comparée à la version actuelle';
  @override
  String get historyTabChanges => 'Modifications';
  @override
  String get historyTabVersion => 'Version';
  @override
  String get historyNoChanges => 'Même texte que la version actuelle.';
  @override
  String get historyRestoreAction => 'Restaurer cette version';
  @override
  String historyRestoreConfirmTitle(String when) =>
      'Restaurer la version ($when) ?';
  @override
  String get historyRestoreConfirmBody =>
      'Le texte actuel est d’abord conservé dans l’historique : vous '
      'pourrez toujours revenir en arrière.';
  @override
  String get historyRestoreConfirm => 'Restaurer';
  @override
  String historyRestored(String when) => 'Version ($when) restaurée';
  @override
  String get historyRestoreFailed => 'Impossible de restaurer la version';
  @override
  String get actionUndo => 'Annuler';
  @override
  String diffLineRange(int start, int end) => 'Lignes $start–$end';
  @override
  String diffLineSingle(int line) => 'Ligne $line';
  @override
  String diffUnchanged(int count) =>
      count < 2 ? '$count ligne inchangée' : '$count lignes inchangées';
  @override
  String get historyTakeHunk => 'Restaurer ici';
  @override
  String historyRestoreSelectedAction(int count) => count == 1
      ? 'Restaurer 1 modification'
      : 'Restaurer $count modifications';
  @override
  String get historyRestoreSelectedConfirmBody =>
      'Les modifications choisies reviennent au texte de cette version. La '
      "note telle qu'elle est maintenant est d'abord conservée comme "
      'version, vous pouvez donc annuler.';
  @override
  String get historyNoteChangedReloaded =>
      'La note a changé pendant que vous étiez ici — la comparaison a été '
      'actualisée.';
  @override
  String get historyVersionsTitle => 'Versions à conserver';
  @override
  String get historyVersionsSubtitle => 'Par note, dans .history/';
  @override
  String historyVersionsValue(int count) => count == 0 ? 'Aucune' : '$count';
  @override
  String get historyIntervalTitle => 'Nouvelle version au plus toutes les';
  @override
  String get historyIntervalSubtitle =>
      'Pendant l’écriture ; commencer à modifier une note en conserve '
      'toujours une';
  @override
  String historyIntervalValue(int minutes) => '$minutes min';
  @override
  String get settingsSectionTranscription => 'Transcription';
  @override
  String get transcriptionModelTitle => 'Modèle';
  @override
  String get transcriptionModelNone => 'Aucun';
  @override
  String get transcriptionLanguageTitle => 'Langue';
  @override
  String get transcriptionLanguageSubtitle =>
      "La langue parlée dans vos enregistrements. L'indiquer est plus précis "
      'que la détecter.';
  @override
  String transcriptionLanguageApp(String language) =>
      "Comme l'application ($language)";
  @override
  String get transcriptionLanguageDetect => 'Détecter automatiquement';
  @override
  String get transcriptionModelsTitle => 'Modèles de transcription';
  @override
  String transcriptionModelsUsed(String size) => '$size utilisés';
  @override
  String get transcriptionModelsInstalled => 'Téléchargés';
  @override
  String get transcriptionModelsDownloading => 'Téléchargement en cours';
  @override
  String get transcriptionModelsAvailable => 'Disponibles';
  @override
  String get transcriptionModelsFooter =>
      "Les modèles restent dans le stockage de l'application sur cet "
      'appareil. Ils ne sont ni copiés dans la bibliothèque ni synchronisés.';
  @override
  String get transcriptionModelDefault => 'Par défaut';
  @override
  String get transcriptionModelSlow => 'Lent';
  @override
  String get transcriptionModelHintTiny => 'Le plus rapide, le moins précis';
  @override
  String get transcriptionModelHintBase =>
      'Bon équilibre entre vitesse et précision';
  @override
  String get transcriptionModelHintSmall => 'Plus précis, environ 3× plus lent';
  @override
  String get transcriptionModelHintMedium =>
      'Très précis, lent sur un téléphone';
  @override
  String get transcriptionModelHintLarge =>
      'Le plus précis, demande beaucoup de mémoire';
  @override
  String get transcriptionModelDownload => 'Télécharger';
  @override
  String transcriptionModelDeleteTitle(String model) =>
      'Supprimer le modèle $model ?';
  @override
  String transcriptionModelDeleteBody(String size) =>
      'Cela libère $size. Vous pourrez retélécharger le modèle plus tard.';
  @override
  String get transcriptionModelFailed =>
      'Échec du téléchargement. Vérifiez la connexion et réessayez.';
  @override
  String get actionRetry => 'Réessayer';
  @override
  String get decimalSeparator => ',';
  @override
  String get transcriptionModelRetrying =>
      'Connexion perdue, nouvelle tentative…';
  @override
  String transcriptionModelInterrupted(String progress) =>
      'En pause à $progress';
  @override
  String get actionResume => 'Reprendre';
  @override
  String get audioTranscribe => 'Transcrire';
  @override
  String get audioTranscribeUnsupported =>
      'Enregistrements WAV uniquement sur cet appareil';
  @override
  String get transcriptionQueued => "En file d'attente";
  @override
  String get transcriptionPreparing => "Préparation de l'audio…";
  @override
  String transcriptionRunning(int percent) => 'Transcription… $percent %';
  @override
  String transcriptionWaitingForModel(String model, int percent) =>
      'Téléchargement de $model · $percent %';
  @override
  String get transcriptionSaved => 'Transcription ajoutée à la description';
  @override
  String get transcriptionNoSpeech =>
      'Aucune parole reconnue dans cet enregistrement';
  @override
  String get transcriptionFailed => 'Échec de la transcription';
  @override
  String get transcriptionPickModelTitle => 'Choisissez un modèle';
  @override
  String get transcriptionPickModelBody =>
      "La transcription se fait sur cet appareil et l'enregistrement n'est "
      "jamais envoyé. Le modèle n'est téléchargé qu'une fois.";
  @override
  String get transcriptionPickModelAction => 'Télécharger et transcrire';
  @override
  String get transcriptionModelRecommended => 'Recommandé';
  @override
  String get transcriptionExistingTitle =>
      'Cet enregistrement a déjà une description';
  @override
  String get transcriptionExistingBody =>
      'La remplacer par la transcription, ou ajouter la transcription en '
      'dessous ?';
  @override
  String get transcriptionAppend => 'Ajouter en dessous';
  @override
  String get transcriptionReplace => 'Remplacer';
  @override
  String get settingsSectionSync => 'Synchronisation';
  @override
  String get syncWebDavTitle => 'WebDAV';
  @override
  String get syncNotConfigured => 'Non configurée pour cette bibliothèque';
  @override
  String get syncNeverSynced => 'Jamais synchronisée';
  @override
  String syncLastSynced(String when) => 'Synchronisée : $when';
  @override
  String get syncRunning => 'Synchronisation…';
  @override
  String syncScreenSubtitle(String library) => 'Bibliothèque $library';
  @override
  String get syncUrlLabel => 'Adresse du dossier';
  @override
  String get syncUrlRequired => 'Saisissez l’adresse du serveur';
  @override
  String get syncUrlHint =>
      'Le dossier doit exister. Copiez l’adresse telle que le '
      'serveur l’affiche.';
  @override
  String get syncHttpWarning =>
      'Connexion non chiffrée : acceptable via un VPN ou sur '
      'votre réseau local.';
  @override
  String get syncUserLabel => 'Utilisateur';
  @override
  String get syncUserHint =>
      'Laissez vide si le serveur ne demande pas d’identifiants.';
  @override
  String get syncPasswordLabel => 'Mot de passe';
  @override
  String get syncPasswordHint =>
      'Conservé dans le trousseau de cet appareil, jamais dans '
      'les fichiers de la bibliothèque.';
  @override
  String get syncPasswordKeepHint =>
      'Laissez vide pour garder le mot de passe enregistré.';
  @override
  String get syncShowPassword => 'Afficher le mot de passe';
  @override
  String get syncHidePassword => 'Masquer le mot de passe';
  @override
  String get syncTestAction => 'Tester la connexion';
  @override
  String get syncTesting => 'Test en cours…';
  @override
  String get syncRetargetWarning =>
      'Avec une autre adresse ou un autre utilisateur, la '
      'prochaine synchronisation repart comme une première '
      'synchronisation.';
  @override
  String get syncTestOk => 'La connexion fonctionne';
  @override
  String get syncModeFull => 'Mode complet';
  @override
  String get syncModeCompatible => 'Mode compatible';
  @override
  String syncTestOkSubtitle(String mode, int ms) => '$mode · $ms ms';
  @override
  String get syncCapBasic => 'Lecture, écriture et suppression';
  @override
  String get syncCapEtags => 'Empreintes des fichiers (ETag)';
  @override
  String get syncCapNoEtags => 'Pas d’empreintes des fichiers (ETag)';
  @override
  String get syncCapNoEtagsDetail =>
      'Je compare taille et date ; en cas de doute, je '
      'retélécharge';
  @override
  String get syncCapGuarded => 'Écritures protégées';
  @override
  String get syncCapUnguarded => 'Écritures non protégées';
  @override
  String get syncCapUnguardedDetail =>
      'Je vérifie le fichier sur le serveur juste avant d’écrire';
  @override
  String get syncCapMove => 'Renommage sans nouvel envoi';
  @override
  String get syncCapNoMove => 'Pas de renommage sur le serveur';
  @override
  String get syncCapNoMoveDetail =>
      'Un renommage devient une suppression et un nouvel envoi';
  @override
  String get syncCompatibleNote =>
      'En mode compatible, la synchronisation fonctionne de la '
      'même façon, avec quelques requêtes de plus.';
  @override
  String get syncTestInvalidUrl => 'Adresse non valide';
  @override
  String get syncTestInvalidUrlHint =>
      'Saisissez une adresse http:// ou https://, sans '
      'utilisateur ni mot de passe dedans.';
  @override
  String get syncTestOffline => 'Serveur injoignable';
  @override
  String get syncTestOfflineHint =>
      'Le VPN est-il actif ? Une adresse 10.x ou 192.168.x ne '
      'fonctionne que depuis le même réseau.';
  @override
  String get syncTestAuth => 'Utilisateur ou mot de passe refusé';
  @override
  String get syncTestAuthHint => 'Vérifiez-les, puis testez à nouveau.';
  @override
  String get syncTestNotFound => 'Le dossier n’existe pas';
  @override
  String get syncTestNotFoundHint =>
      'Créez-le sur le serveur ou corrigez l’adresse.';
  @override
  String get syncTestUnsupported => 'Ce n’est pas un dossier WebDAV';
  @override
  String get syncTestUnsupportedHint =>
      'Le serveur répond, mais pas en WebDAV.';
  @override
  String get syncTestFailed => 'Le test n’a pas abouti';
  @override
  String get syncNowAction => 'Synchroniser maintenant';
  @override
  String get syncSectionServer => 'Serveur';
  @override
  String get syncServerRow => 'Adresse, utilisateur et mot de passe';
  @override
  String get syncRetestTitle => 'Tester à nouveau le serveur';
  @override
  String syncProbedAgo(String when) => 'Dernier test : $when';
  @override
  String get syncDisconnectTitle => 'Déconnecter cette bibliothèque';
  @override
  String get syncDisconnectSubtitle =>
      'Les fichiers restent ici et sur le serveur';
  @override
  String get syncDisconnectConfirmTitle => 'Déconnecter la synchronisation ?';
  @override
  String get syncDisconnectConfirmBody =>
      'Cette bibliothèque ne se synchronise plus sur cet '
      'appareil. Aucun fichier n’est supprimé, ni ici ni sur le '
      'serveur. Si vous la reconnectez, la première '
      'synchronisation recommence depuis le début.';
  @override
  String get syncDisconnectConfirm => 'Déconnecter';
  @override
  String get syncFirstTitle => 'Première synchronisation';
  @override
  String get syncFirstIntro =>
      'J’ai comparé la bibliothèque avec le dossier sur le '
      'serveur :';
  @override
  String get syncFirstUpload => 'À envoyer';
  @override
  String get syncFirstDownload => 'À télécharger';
  @override
  String get syncFirstBoth => 'Des deux côtés';
  @override
  String get syncFirstBothHint =>
      'Identiques : aucun transfert. Différents : à résoudre';
  @override
  String get syncFirstNoDelete =>
      'La première synchronisation ne supprime rien, ni ici ni '
      'sur le serveur.';
  @override
  String get syncStartAction => 'Démarrer';
  @override
  String syncMassTrashTitle(int count) =>
      'Mettre $count fichiers à la corbeille ?';
  @override
  String syncMassTrashBody(int count, int total) =>
      '$count des $total fichiers synchronisés manquent sur le '
      'serveur. En général, cela signifie une mauvaise adresse, '
      'un disque du NAS non monté ou un dossier vidé par erreur.';
  @override
  String get syncMassTrashHint =>
      'Si vous les avez vraiment supprimés sur un autre '
      'appareil, confirmez : ici, ils vont à la corbeille.';
  @override
  String get syncMassTrashConfirm => 'Mettre à la corbeille';
  @override
  String syncMassDeleteTitle(int count) =>
      'Supprimer $count fichiers du serveur ?';
  @override
  String syncMassDeleteBody(int count, int total) =>
      '$count des $total fichiers synchronisés manquent ici. Si '
      'vous ne les avez pas supprimés, annulez et vérifiez le '
      'dossier de la bibliothèque.';
  @override
  String get syncMassDeleteConfirm => 'Supprimer du serveur';
  @override
  String get syncTooltip => 'Synchroniser';
  @override
  String get syncStageConnecting => 'Connexion au serveur…';
  @override
  String get syncStageComparing => 'Comparaison avec le serveur…';
  @override
  String syncStageApplying(int done, int total) =>
      'Synchronisation · $done sur $total';
  @override
  String get syncStatusWarnings => 'Synchronisée avec des avertissements';
  @override
  String syncConflictsHeader(int count) =>
      'Modifiés ici et sur le serveur · $count';
  @override
  String get syncConflictHint => 'Aucune des deux versions n’a été touchée';
  @override
  String get syncResolveAction => 'Résoudre';
  @override
  String syncFailuresHeader(int count) => 'Non synchronisés · $count';
  @override
  String get syncFailuresHint => 'Nouvel essai à la prochaine synchronisation';
  @override
  String get syncAbortAuth => 'Mot de passe refusé par le serveur';
  @override
  String get syncAbortMissingPassword => 'Aucun mot de passe enregistré';
  @override
  String get syncAbortOffline => 'Serveur injoignable';
  @override
  String get syncAbortRemoteMissing =>
      'Le dossier sur le serveur n’existe plus';
  @override
  String get syncAbortUnsupported => 'Le serveur ne fonctionne plus en WebDAV';
  @override
  String get syncAbortFailed => 'La synchronisation n’a pas abouti';
  @override
  String get syncAbortNotConfirmed => 'Synchronisation annulée';
  @override
  String get syncAbortNothingTouched =>
      'Aucun fichier n’a été touché. Vos modifications restent '
      'ici jusqu’à la prochaine synchronisation réussie.';
  @override
  String syncLastSuccess(String when) =>
      'Dernière synchronisation réussie : $when';
  @override
  String get syncNoSuccessYet =>
      'Aucune synchronisation réussie pour l’instant';
  @override
  String get syncUpdatePasswordAction => 'Mettre à jour le mot de passe';
  @override
  String get syncRetryAction => 'Réessayer';
  @override
  String get syncOpenSettingsAction => 'Paramètres';
  @override
  String get syncCloseAction => 'Fermer';
  @override
  String get syncDoneSnack => 'Synchronisée';
  @override
  String syncTrashedSnack(int count) => count == 1
      ? 'Synchronisée · 1 fichier supprimé ailleurs est dans la '
            'corbeille'
      : 'Synchronisée · $count fichiers supprimés ailleurs sont '
            'dans la corbeille';
  @override
  String syncConflictsSnack(int count) => count == 1
      ? 'Synchronisée · 1 conflit à résoudre'
      : 'Synchronisée · $count conflits à résoudre';
  @override
  String get syncShowAction => 'Afficher';
  @override
  String get syncConflictTitle => 'Résoudre le conflit';
  @override
  String get syncConflictLegend =>
      'Les lignes marquées − sont celles du serveur, les lignes '
      'marquées + celles de cet appareil.';
  @override
  String get syncConflictBinary =>
      'Ce n’est pas un fichier texte : choisissez la copie à '
      'garder.';
  @override
  String get syncConflictKeepNote =>
      'La copie que vous ne gardez pas reste dans l’historique '
      'de la note.';
  @override
  String get syncKeepLocal => 'Garder celle de cet appareil';
  @override
  String get syncKeepRemote => 'Garder celle du serveur';
  @override
  String get syncConflictIdentical => 'Les deux versions sont identiques';
  @override
  String get syncConflictLoadFailed => 'Impossible de lire les deux versions';
  @override
  String get syncResolveFailed => 'Impossible de résoudre le conflit';
  @override
  String get syncResolved => 'Conflit résolu';
  @override
  String get syncSectionWhen => 'Quand synchroniser';
  @override
  String get syncAutoTitle => 'Automatiquement';
  @override
  String get syncAutoSubtitle =>
      'Après les modifications, à l’ouverture et à intervalles';
  @override
  String get syncIntervalTitle => 'Vérifier le serveur toutes les';
  @override
  String get syncIntervalSubtitle => 'Seulement quand l’app est ouverte';
  @override
  String get syncIntervalDialogBody =>
      'Pour voir les modifications faites sur d’autres appareils pendant que '
      'l’app est ouverte. Avec « Jamais », seulement après les modifications '
      'et à l’ouverture.';
  @override
  String syncIntervalMinutes(int count) =>
      count == 1 ? '1 minute' : '$count minutes';
  @override
  String get syncIntervalNever => 'Jamais';
  @override
  String get syncWifiOnlyTitle => 'Wi-Fi uniquement';
  @override
  String get syncWifiOnlySubtitle =>
      'En données mobiles, synchroniser seulement à la main';
  @override
  String syncPendingChanges(int count) => count == 1
      ? '1 modification en attente'
      : '$count modifications en attente';
  @override
  String syncRetryIn(String wait) => 'nouvel essai dans $wait';
  @override
  String syncWaitSeconds(int seconds) => '$seconds s';
  @override
  String syncWaitMinutes(int minutes) => '$minutes min';
  @override
  String get syncWaitingForWifi => 'En attente du Wi-Fi';
  @override
  String get syncWaitingForNetwork => 'En attente d’une connexion';
  @override
  String get syncMobileDataHint =>
      '« Synchroniser maintenant » utilise quand même les données mobiles.';
  @override
  String get syncQueueKeptHint =>
      'Les modifications restent ici, même si vous fermez l’app, et partent '
      'd’elles-mêmes quand le serveur répond.';
  @override
  String get syncAutoPaused => 'Synchronisation automatique en pause';
  @override
  String get syncPausedAuthHint =>
      'Elle reprend quand vous mettez à jour le mot de passe ou synchronisez '
      'à la main.';
  @override
  String get syncPausedServerHint =>
      'Elle reprend quand vous corrigez l’adresse ou synchronisez à la main.';
  @override
  String get syncPausedConfirmHint =>
      '« Synchroniser maintenant » montre ce qui serait supprimé et demande '
      'd’abord.';
  @override
  String get syncNeedsConfirmation => 'En attente de votre confirmation';
  @override
  String get syncMergeIntro =>
      'Les modifications qui ne se chevauchent pas sont déjà fusionnées ; '
      'choisissez quoi garder là où elles se chevauchent.';
  @override
  String get syncMergeClean =>
      'Les deux versions fusionnent d’elles-mêmes : rien ne se chevauche.';
  @override
  String get syncMergeNoBase =>
      'Aucune version commune sur laquelle fusionner : il faut choisir le '
      'fichier entier.';
  @override
  String syncMergeOverlap(int index, int total) =>
      'Chevauchement $index sur $total';
  @override
  String get syncMergeFromLocal => 'De cet appareil';
  @override
  String get syncMergeFromRemote => 'Du serveur';
  @override
  String get syncMergeRemovedLines => 'Lignes supprimées';
  @override
  String get syncMergeKeepLocal => 'Les miennes';
  @override
  String get syncMergeKeepRemote => 'Du serveur';
  @override
  String get syncMergeKeepBoth => 'Les deux';
  @override
  String get syncMergeSave => 'Enregistrer la fusion';
  @override
  String get syncMergeKeepWhole => 'Ou garder une copie entière';
}
