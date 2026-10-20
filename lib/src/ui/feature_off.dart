/// The one sentence a surface says when something leads to a feature that
/// is off in the library (#1109): a launcher shortcut, a notification, a
/// widget tap. A screen that is not there would be a broken one.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/ui/feature_names.dart';
import 'package:niman/src/ui/strings.dart';

/// "Todo and reminders is off in this library", say.
String featureOffSentence(LibraryFeature feature) =>
    AppStrings.featureOffInLibraryNamed(featureName(feature));

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
        persist: false,
        action: openFeatures == null
            ? null
            : SnackBarAction(
                label: AppStrings.widgetOpenFeatures,
                onPressed: openFeatures,
              ),
      ),
    );
}
