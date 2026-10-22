/// The sections of Settings → Features (#1109): which switches sit under
/// which heading, in the order the screen lists them.
library;

import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/ui/strings.dart';

/// One heading of the screen and the switches under it.
typedef FeatureSection = ({String title, List<LibraryFeature> features});

/// The sections, titled in the language in use. A child follows its parent,
/// which is how the screen draws it: indented under it.
List<FeatureSection> featureSections() => [
  (
    title: AppStrings.featuresSectionFinding,
    features: [
      LibraryFeature.search,
      LibraryFeature.quickNote,
      LibraryFeature.templates,
      LibraryFeature.capture,
    ],
  ),
  (
    title: AppStrings.featuresSectionPlanning,
    features: [
      LibraryFeature.todo,
      LibraryFeature.journal,
      LibraryFeature.calendar,
    ],
  ),
  (
    title: AppStrings.featuresSectionKinds,
    features: [
      LibraryFeature.kindList,
      LibraryFeature.kindShopping,
      LibraryFeature.kindAudio,
      LibraryFeature.transcription,
      LibraryFeature.kindSlides,
      LibraryFeature.kindFlashcards,
      LibraryFeature.kindKanban,
    ],
  ),
  (
    title: AppStrings.featuresSectionReading,
    features: [
      LibraryFeature.readers,
      LibraryFeature.annotations,
      LibraryFeature.ocr,
    ],
  ),
  (
    title: AppStrings.featuresSectionAround,
    features: [LibraryFeature.home, LibraryFeature.widgets],
  ),
];
