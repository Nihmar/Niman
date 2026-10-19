/// The one sentence a surface says when something leads to a feature that
/// is off in the library (#1109): a launcher shortcut, a notification, a
/// widget tap. A screen that is not there would be a broken one.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/ui/strings.dart';

/// "Todo is off in this library", say, or the unnamed form for a feature
/// that has no name among the strings yet.
String featureOffSentence(LibraryFeature feature) => switch (_nameOf(feature)) {
  final name? => AppStrings.featureOffNamed(name),
  null => AppStrings.featureOffUnnamed,
};

// phase 2 names: the Features screen gives each feature a name of its own;
// until it lands this borrows the ones the app already says, and a feature
// with none is said without a name.
String? _nameOf(LibraryFeature feature) => switch (feature) {
  LibraryFeature.search => AppStrings.tabSearch,
  LibraryFeature.quickNote => AppStrings.quickNoteTitle,
  LibraryFeature.todo => AppStrings.todoTitle,
  LibraryFeature.journal => AppStrings.paletteGroupJournal,
  LibraryFeature.calendar => AppStrings.journalCalendarTitle,
  LibraryFeature.kindList => AppStrings.cheatLists,
  LibraryFeature.kindShopping => AppStrings.shoppingListName,
  LibraryFeature.kindFlashcards => AppStrings.flashcardsName,
  LibraryFeature.ocr => AppStrings.settingsSectionTextRecognition,
  LibraryFeature.home => AppStrings.tabHome,
  LibraryFeature.templates ||
  LibraryFeature.capture ||
  LibraryFeature.kindAudio ||
  LibraryFeature.transcription ||
  LibraryFeature.kindSlides ||
  LibraryFeature.readers ||
  LibraryFeature.annotations ||
  LibraryFeature.widgets => null,
};

/// Says [feature] is off, in a snack bar; [openFeatures], when given, is
/// its action.
void showFeatureOff(
  BuildContext context,
  LibraryFeature feature, {
  VoidCallback? openFeatures,
}) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(featureOffSentence(feature)),
        action: openFeatures == null
            ? null
            : SnackBarAction(
                label: AppStrings.widgetOpenFeatures,
                onPressed: openFeatures,
              ),
      ),
    );
}
