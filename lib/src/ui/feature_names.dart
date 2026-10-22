/// How a feature is called on screen (#1109): the Features screen's rows,
/// the palette's quiet line, the Navigation area's.
library;

import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/ui/strings.dart';

/// [feature]'s name in the language in use.
///
/// An exhaustive `switch`, like the classifiers: a feature added without a
/// name does not compile.
String featureName(LibraryFeature feature) => switch (feature) {
  LibraryFeature.search => AppStrings.featureNameSearch,
  LibraryFeature.quickNote => AppStrings.featureNameQuickNote,
  LibraryFeature.templates => AppStrings.featureNameTemplates,
  LibraryFeature.capture => AppStrings.featureNameCapture,
  LibraryFeature.todo => AppStrings.featureNameTodo,
  LibraryFeature.journal => AppStrings.featureNameJournal,
  LibraryFeature.calendar => AppStrings.featureNameCalendar,
  LibraryFeature.kindList => AppStrings.featureNameLists,
  LibraryFeature.kindShopping => AppStrings.featureNameShopping,
  LibraryFeature.kindAudio => AppStrings.featureNameAudio,
  LibraryFeature.transcription => AppStrings.featureNameTranscription,
  LibraryFeature.kindSlides => AppStrings.featureNameSlides,
  LibraryFeature.kindFlashcards => AppStrings.featureNameFlashcards,
  LibraryFeature.kindKanban => AppStrings.featureNameKanban,
  LibraryFeature.readers => AppStrings.featureNameReaders,
  LibraryFeature.annotations => AppStrings.featureNameAnnotations,
  LibraryFeature.ocr => AppStrings.featureNameOcr,
  LibraryFeature.home => AppStrings.featureNameHome,
  LibraryFeature.widgets => AppStrings.featureNameWidgets,
};
