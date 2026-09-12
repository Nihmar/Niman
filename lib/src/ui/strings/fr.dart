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
  String get keyboardOnOpenTitle => 'Clavier à l’ouverture';
  @override
  String get keyboardOnOpenSubtitle =>
      'Affiche le clavier dès qu’une note s’ouvre (off = au premier tap)';
  @override
  String get editorKindSource => 'Source Markdown';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
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
  String get themePaletteTitle => 'Palette';
  @override
  String get themePaletteSubtitle =>
      'Les couleurs de l’interface et de la note';
  @override
  String get themePaletteSystem => 'Système';

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

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Note rapide';
  @override
  String get shortcutNewTodo => 'Nouvelle tâche';
  @override
  String get shortcutNewNote => 'Nouvelle note';
  @override
  String get shortcutNewList => 'Nouvelle liste';
  @override
  String get shortcutToggleSidebar =>
      'Afficher ou masquer l’arborescence des fichiers';
  @override
  String get shortcutEditorSection => 'Dans l’éditeur';
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
  String get newFolderTitle => 'Nouveau dossier';
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
}
